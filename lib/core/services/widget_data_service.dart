import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';

/// Bridges Flutter ↔ native (iOS Widget Extension / Android Glance widget).
///
/// The widget only ever shows the **most recently opened loyalty card**.
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

      final gradients = LinearGradients().linearGradientList;
      final gradient =
          gradients[card.colorId.clamp(0, gradients.length - 1)];
      final colors = gradient.colors;
      final color1 = colors.isNotEmpty ? colors.first : const Color(0xFF1A1D24);
      final color2 = colors.length > 1 ? colors.last : color1;

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

      debugPrint(
        '[WidgetDataService] wrote card id=${card.id} name=${card.name} '
        'barcode=${card.barcode} format=${card.barcodeFormat}',
      );

      await _refresh();
      debugPrint('[WidgetDataService] reloadAllTimelines triggered '
          '(widget=$_iOSWidgetName)');
    } catch (e) {
      debugPrint('WidgetDataService.setLastUsedLoyaltyCard error: $e');
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
      ]);
      await _refresh();
    } catch (e) {
      debugPrint('WidgetDataService.clearLastUsedLoyaltyCard error: $e');
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

  /// Make the widget show *something* without requiring the user to
  /// open a card first. Called on every card-list reload:
  ///   - empty cache + cards exist → seed with the newest card
  ///   - cached id no longer in the list → re-seed with the newest
  ///   - cached id still present → leave it (respect the user's last
  ///     opened pick)
  Future<void> reconcile(List<LoyaltyCard> cards) async {
    if (cards.isEmpty) {
      await clearLastUsedLoyaltyCard();
      return;
    }
    final cachedId = await getCachedLoyaltyId();
    if (cachedId != null && cards.any((c) => c.id == cachedId)) {
      return;
    }
    final sorted = [...cards]..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    await setLastUsedLoyaltyCard(sorted.first);
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
