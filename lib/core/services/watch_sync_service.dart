import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';

/// Bridges loyalty cards from Dart → native iOS → Apple Watch.
///
/// The native side (`AppDelegate.swift`) forwards the JSON payload to
/// `WCSession.updateApplicationContext`, which has last-write-wins
/// semantics and is replayed automatically when the watch wakes / the
/// watch app launches. So we always send the *full* card list, never
/// deltas — the watch reconstructs its UI from the latest snapshot it
/// has cached.
///
/// All operations are silent no-ops on Android. The channel only exists
/// on iOS; calling it elsewhere would throw `MissingPluginException`.
class WatchSyncService {
  WatchSyncService._();
  static final WatchSyncService instance = WatchSyncService._();

  static const MethodChannel _channel =
      MethodChannel('app.cardwallet/watch_sync');

  /// Bump when the payload shape changes incompatibly. Watch refuses
  /// to apply any version higher than it understands (see
  /// `LoyaltyCardStore.swift`).
  static const int _payloadVersion = 1;

  /// In-flight coalescing: if `pushAllCards` is called several times
  /// in quick succession (e.g. an import that adds 20 cards in a row),
  /// only the last payload actually crosses the WatchConnectivity wire.
  Timer? _coalesceTimer;
  List<LoyaltyCard>? _pendingCards;

  /// Schedule a push. Coalesces bursts of calls into a single transfer
  /// to avoid hammering WCSession during bulk updates.
  void scheduleSync(List<LoyaltyCard> cards) {
    if (!_isSupportedPlatform) return;
    _pendingCards = cards;
    _coalesceTimer?.cancel();
    _coalesceTimer = Timer(const Duration(milliseconds: 350), () {
      final pending = _pendingCards;
      _pendingCards = null;
      if (pending == null) return;
      unawaited(_pushNow(pending));
    });
  }

  /// Immediate push, bypassing the coalescing window. Useful for the
  /// "user just deleted their last card and we want the watch to
  /// reflect that *now*" case.
  Future<bool> pushAllCards(List<LoyaltyCard> cards) {
    if (!_isSupportedPlatform) return Future.value(false);
    _coalesceTimer?.cancel();
    _pendingCards = null;
    return _pushNow(cards);
  }

  /// WCSession.updateApplicationContext silently rejects payloads over
  /// ~65KB. Log a warning at 60KB so the issue is debuggable before it
  /// happens in the wild (most users sit well below this — 300+ loyalty
  /// cards would be the practical trigger).
  static const int _wcPayloadWarnBytes = 60 * 1024;

  Future<bool> _pushNow(List<LoyaltyCard> cards) async {
    try {
      final json = _encodePayload(cards);
      final byteLen = utf8.encode(json).length;
      if (byteLen > _wcPayloadWarnBytes) {
        debugPrint(
          'WatchSyncService: payload ${(byteLen / 1024).toStringAsFixed(1)}KB '
          'approaching the 65KB WatchConnectivity limit '
          '(${cards.length} cards). Sync may be silently dropped.',
        );
      }
      final result =
          await _channel.invokeMethod<bool>('pushAllCards', json);
      return result ?? false;
    } on MissingPluginException {
      // Watch sync is iOS-only; on Android (or unsupported platform)
      // the channel isn't registered. Silent skip.
      return false;
    } on PlatformException catch (e) {
      debugPrint('WatchSyncService.pushAllCards error: $e');
      return false;
    } catch (e) {
      debugPrint('WatchSyncService.pushAllCards unexpected: $e');
      return false;
    }
  }

  /// Probe whether the user has a paired watch with the companion app
  /// installed. Returns `(false, false)` on platforms / configurations
  /// where the answer can't be known.
  Future<({bool paired, bool installed})> probePairingStatus() async {
    if (!_isSupportedPlatform) {
      return (paired: false, installed: false);
    }
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('isPaired');
      if (result == null) return (paired: false, installed: false);
      final paired = (result['paired'] as bool?) ?? false;
      final installed = (result['installed'] as bool?) ?? false;
      return (paired: paired, installed: installed);
    } on MissingPluginException {
      return (paired: false, installed: false);
    } on PlatformException catch (e) {
      debugPrint('WatchSyncService.probePairingStatus error: $e');
      return (paired: false, installed: false);
    }
  }

  bool get _isSupportedPlatform {
    // dart:io Platform isn't available on web, but this app is mobile-
    // only. Still, the check keeps us from crashing if the file is
    // ever pulled into a web build.
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  String _encodePayload(List<LoyaltyCard> cards) {
    final gradients = LinearGradients().linearGradientList;
    final cardMaps = cards.map((c) {
      final gradient =
          gradients[c.colorId.clamp(0, gradients.length - 1)];
      final colors = gradient.colors;
      final color1 =
          colors.isNotEmpty ? colors.first : const Color(0xFF1A1D24);
      final color2 = colors.length > 1 ? colors.last : color1;
      return <String, dynamic>{
        'id': c.id,
        'name': c.name,
        'brand': c.brand ?? '',
        'barcode': c.barcode,
        'format': c.barcodeFormat,
        'color1': _hex(color1),
        'color2': _hex(color2),
      };
    }).toList();

    return jsonEncode(<String, dynamic>{
      'version': _payloadVersion,
      'cards': cardMaps,
    });
  }

  String _hex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
