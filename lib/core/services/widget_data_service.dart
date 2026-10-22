import 'dart:async';
import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/utils/loyalty_usage.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_formats.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_validator.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';

/// Bridges Flutter ↔ native (iOS Widget Extension / Android Glance widget).
///
/// The widgets show the loyalty card the user most likely needs now ("Up
/// Next", from their own usage pattern) plus the next few.
/// Snapshot fields are written to the shared App Group (iOS) /
/// SharedPreferences (Android) container so the native widget can render
/// without touching the encrypted Hive box.
///
/// Nothing sensitive lives here: loyalty barcodes are designed to be shown
/// to a cashier. Credit cards and IBANs intentionally never reach the
/// widget surface.
class WidgetDataService {
  WidgetDataService._();
  static final WidgetDataService instance = WidgetDataService._();

  /// Must match the App Group identifier configured on both the Runner
  /// target and the Widget Extension target in Xcode.
  static const String _iOSAppGroupId = 'group.com.volkan.walletapp';

  /// Widget identifiers — must match the SwiftUI `@main` widget struct name
  /// on iOS and the AppWidgetProvider receiver class on Android.
  static const String _iOSWidgetName = 'LoyaltyWidget';
  static const String _androidWidgetReceiver =
      'com.volkan.wallet_app.LoyaltyWidgetReceiver';

  // Keys written to the shared store. Native widget reads the same keys.
  static const String _keyId = 'last_loyalty_id';
  static const String _keyName = 'last_loyalty_name';
  static const String _keyBrand = 'last_loyalty_brand';
  static const String _keyBarcode = 'last_loyalty_barcode';
  static const String _keyFormat = 'last_loyalty_format';
  static const String _keyColor1 = 'last_loyalty_color1';
  static const String _keyColor2 = 'last_loyalty_color2';
  static const String _keyUsedAt = 'last_loyalty_used_at';

  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await HomeWidget.setAppGroupId(_iOSAppGroupId);
    _initialized = true;
  }

  /// Push a loyalty card snapshot to the widget. Called every time the
  /// detail / barcode page is opened — that interaction is what defines
  /// "most recently used" for the widget.
  Future<void> setLastUsedLoyaltyCard(LoyaltyCard card) async {
    try {
      await _ensureInit();

      final colors = materialForItem(WalletItem.loyalty(card)).colors;
      final color1 = colors.first;
      final color2 = colors.last;

      await Future.wait([
        HomeWidget.saveWidgetData<String>(_keyId, card.id),
        HomeWidget.saveWidgetData<String>(_keyName, card.name),
        HomeWidget.saveWidgetData<String>(_keyBrand, card.brand ?? ''),
        HomeWidget.saveWidgetData<String>(_keyBarcode, card.barcode),
        HomeWidget.saveWidgetData<String>(_keyFormat, card.barcodeFormat),
        HomeWidget.saveWidgetData<String>(_keyColor1, _toHex(color1)),
        HomeWidget.saveWidgetData<String>(_keyColor2, _toHex(color2)),
        HomeWidget.saveWidgetData<String>(
          _keyUsedAt,
          DateTime.now().toIso8601String(),
        ),
      ]);

      await _refresh();
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'WidgetDataService.set');
    }
  }

  /// Clear the widget snapshot — call when the previously-shown card is
  /// deleted and no other card should be promoted in its place. Native
  /// widget falls back to the empty state ("Add loyalty card").
  Future<void> clearLastUsedLoyaltyCard() async {
    try {
      await _ensureInit();
      await Future.wait([
        HomeWidget.saveWidgetData<String>(_keyId, ''),
        HomeWidget.saveWidgetData<String>(_keyName, ''),
        HomeWidget.saveWidgetData<String>(_keyBrand, ''),
        HomeWidget.saveWidgetData<String>(_keyBarcode, ''),
        HomeWidget.saveWidgetData<String>(_keyFormat, ''),
        HomeWidget.saveWidgetData<String>(_keyColor1, ''),
        HomeWidget.saveWidgetData<String>(_keyColor2, ''),
        HomeWidget.saveWidgetData<String>(_keyUsedAt, ''),
        HomeWidget.saveWidgetData<String>(_keyCards, '[]'),
        HomeWidget.saveWidgetData<String>(_keyTimeline, '[]'),
      ]);
      await _refresh();
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'WidgetDataService.clear');
    }
  }

  /// Read back the currently-cached widget card id. Used after deletion
  /// to decide whether the deleted card was the one the widget shows.
  Future<String?> getCachedLoyaltyId() async {
    try {
      await _ensureInit();
      final id = await HomeWidget.getWidgetData<String>(_keyId);
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  /// Called on every loyalty box change (add / edit / delete / use).
  /// Publishes the v2 widget data — an hourly "Up Next" timeline for the
  /// next 24 hours, the cards it references and a pre-rendered barcode
  /// image per card — so the home/lock-screen widgets stay right through
  /// the day without the app being opened. The legacy `last_loyalty_*`
  /// keys mirror the current Up Next card (quick tile, older widgets).
  Future<void> reconcile(List<LoyaltyCard> cards) async {
    if (cards.isEmpty) {
      await clearLastUsedLoyaltyCard();
      return;
    }
    try {
      await _ensureInit();
      final now = DateTime.now();
      final hour0 = DateTime(now.year, now.month, now.day, now.hour);
      final timeline = <Map<String, Object>>[];
      final used = <String>{};
      for (var h = 0; h < 24; h++) {
        final t = hour0.add(Duration(hours: h));
        // Score at the middle of the hour.
        final ranked = sortLoyaltyForNow(cards, t.add(const Duration(minutes: 30)));
        final ids = [for (final c in ranked.take(4)) c.id];
        used.addAll(ids);
        timeline.add({'t': t.millisecondsSinceEpoch ~/ 1000, 'ids': ids});
      }
      final byId = {for (final c in cards) c.id: c};
      final payload = <Map<String, Object?>>[];
      for (final id in used) {
        final card = byId[id];
        if (card == null) continue;
        final m = materialForItem(WalletItem.loyalty(card));
        payload.add({
          'id': card.id,
          'name': card.name.trim().isNotEmpty ? card.name.trim() : (card.brand ?? ''),
          'barcode': card.barcode,
          'format': card.barcodeFormat,
          'bg': _toHex(m.base),
          'bg2': _toHex(m.colors.first),
          'fg': _toHex(m.foreground),
          'img': await _barcodeImage(card),
        });
      }
      await Future.wait([
        HomeWidget.saveWidgetData<String>(_keyCards, jsonEncode(payload)),
        HomeWidget.saveWidgetData<String>(_keyTimeline, jsonEncode(timeline)),
        // Widgets follow the in-app language, not the system one.
        HomeWidget.saveWidgetData<String>(_keyLabelUpNext, 'cwUpNext'.tr()),
        HomeWidget.saveWidgetData<String>(_keyLabelAdd, 'cwQsLoyalty'.tr()),
      ]);
      await _writeLegacy(sortLoyaltyForNow(cards, now).first);
      await _refresh();
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'WidgetDataService.reconcile');
    }
  }

  static const String _keyCards = 'cw_cards';
  static const String _keyLabelUpNext = 'cw_label_upnext';
  static const String _keyLabelAdd = 'cw_label_add';
  static const String _keyTimeline = 'cw_timeline';

  /// Path of a PNG of [card]'s barcode in the shared container, rendered
  /// with the same encoder as the app (every format, incl. EAN/UPC which
  /// iOS can't draw natively). Re-rendered only when the value changes.
  Future<String?> _barcodeImage(LoyaltyCard card) async {
    final key = 'cw_bc_${card.id}';
    final sigKey = 'cw_bc_sig_${card.id}';
    final sig = '${card.barcodeFormat}:${card.barcode}';
    try {
      final oldSig = await HomeWidget.getWidgetData<String>(sigKey);
      final oldPath = await HomeWidget.getWidgetData<String>(key);
      if (oldSig == sig && oldPath != null && oldPath.isNotEmpty) {
        return oldPath;
      }
      if (!LoyaltyBarcodeValidator.canEncode(card.barcode, card.barcodeFormat)) {
        return null;
      }
      final square = isSquareBarcodeFormat(card.barcodeFormat);
      final size = square ? const Size(300, 300) : const Size(600, 200);
      final barcode = card.barcodeFormat == 'QR_CODE'
          ? Barcode.qrCode()
          : LoyaltyBarcodeValidator.barcodeFor(card.barcodeFormat);
      if (barcode == null) return null;
      final path = await HomeWidget.renderFlutterWidget(
        SizedBox.fromSize(
          size: size,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: BarcodeWidget(
                barcode: barcode,
                data: card.barcode,
                drawText: false,
                color: const Color(0xFF000000),
                backgroundColor: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        key: key,
        logicalSize: size,
        pixelRatio: 2,
      );
      await HomeWidget.saveWidgetData<String>(sigKey, sig);
      return path is String ? path : await HomeWidget.getWidgetData<String>(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLegacy(LoyaltyCard card) async {
    final m = materialForItem(WalletItem.loyalty(card));
    await Future.wait([
      HomeWidget.saveWidgetData<String>(_keyId, card.id),
      HomeWidget.saveWidgetData<String>(_keyName, card.name),
      HomeWidget.saveWidgetData<String>(_keyBrand, card.brand ?? ''),
      HomeWidget.saveWidgetData<String>(_keyBarcode, card.barcode),
      HomeWidget.saveWidgetData<String>(_keyFormat, card.barcodeFormat),
      HomeWidget.saveWidgetData<String>(_keyColor1, _toHex(m.colors.first)),
      HomeWidget.saveWidgetData<String>(_keyColor2, _toHex(m.colors.last)),
    ]);
  }

  Future<void> _refresh() async {
    await HomeWidget.updateWidget(
      name: _iOSWidgetName,
      iOSName: _iOSWidgetName,
      qualifiedAndroidName: _androidWidgetReceiver,
    );
  }

  String _toHex(Color c) {
    // Use 32-bit ARGB int via `toARGB32`. `.value` is deprecated on newer
    // Flutter SDKs because of wide-gamut work; toARGB32 is the supported
    // path for "give me back the integer I'd pass to Color()".
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
