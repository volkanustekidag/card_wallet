import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart';

/// Routes incoming widget taps (`cardwallet://loyalty?id=<id>`) to the
/// loyalty card detail / barcode page.
///
/// The widget surface is *outside the PIN gate*: tapping a loyalty
/// barcode widget on the lock screen needs to put the cashier-facing
/// barcode on the user's screen, fast. The widget only ever exposes
/// loyalty cards — credit cards and IBANs intentionally never reach this
/// path — so the security trade is acceptable. Backing out of the detail
/// page exits the app instead of dropping into the unlocked home; the
/// user has to re-launch normally to get past the PIN.
class WidgetDeepLinkHandler {
  WidgetDeepLinkHandler._();
  static final WidgetDeepLinkHandler instance = WidgetDeepLinkHandler._();

  static const String _scheme = 'cardwallet';
  static const String _loyaltyHost = 'loyalty';
  static const String _idParam = 'id';

  /// Must match `WidgetDataService._iOSAppGroupId` and the App Group
  /// configured on Runner + the widget target in Xcode. We set it here
  /// (not just in WidgetDataService) because deep-link queries hit the
  /// native plugin before any widget data write has had a chance to
  /// run setAppGroupId.
  static const String _iOSAppGroupId = 'group.com.volkan.walletapp';

  /// Populated when the app is cold-launched by a widget tap, before the
  /// splash page has had a chance to route. Splash reads + consumes it,
  /// bypassing the auth gate.
  Uri? pendingColdLaunchUri;

  bool _initialized = false;
  StreamSubscription<Uri?>? _clickSubscription;

  /// Wire up the warm-launch stream and capture cold-launch URI. Safe to
  /// call multiple times; subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // The home_widget plugin on iOS rejects every call with -7 until
      // an App Group ID has been registered. We have to set it before
      // the first read or this whole handler is dead on cold launch.
      await HomeWidget.setAppGroupId(_iOSAppGroupId);
    } catch (e) {
      debugPrint('WidgetDeepLinkHandler setAppGroupId error: $e');
    }

    try {
      pendingColdLaunchUri =
          await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('WidgetDeepLinkHandler cold launch error: $e');
    }

    _clickSubscription = HomeWidget.widgetClicked.listen((uri) {
      if (uri == null) return;
      // Warm path: app already on screen, route immediately.
      unawaited(_routeForUri(uri, fromColdLaunch: false));
    });
  }

  /// Called by the splash page when it boots. If a widget cold-launch URI
  /// is pending, navigate straight to the detail page and return true so
  /// the splash skips its normal onboarding / auth / home decision.
  Future<bool> handleColdLaunchFromSplash() async {
    final uri = pendingColdLaunchUri;
    if (uri == null) return false;
    pendingColdLaunchUri = null;
    return _routeForUri(uri, fromColdLaunch: true);
  }

  /// Cold-launch helper for the splash page when the URI scheme was
  /// already consumed by `GetMaterialApp`'s built-in parser (it strips
  /// the scheme + host, leaving just the query). Splash can read
  /// `Get.parameters['id']` and call this to skip auth and jump
  /// straight to the loyalty barcode page.
  Future<bool> routeToLoyaltyCardById(String id) async {
    if (id.isEmpty) return false;
    final synthetic = Uri.parse('cardwallet://loyalty?id=$id');
    return _routeForUri(synthetic, fromColdLaunch: true);
  }

  Future<bool> _routeForUri(Uri uri, {required bool fromColdLaunch}) async {
    if (uri.scheme != _scheme) return false;
    if (uri.host != _loyaltyHost) return false;

    final id = uri.queryParameters[_idParam];
    if (id == null || id.isEmpty) return false;

    try {
      final service = LoyaltyCardService();
      await service.openBox();
      final cards = await service.getAllLoyaltyCards();
      LoyaltyCard? match;
      for (final c in cards) {
        if (c.id == id) {
          match = c;
          break;
        }
      }
      if (match == null) return false;
      final card = match;

      if (fromColdLaunch) {
        // Seed the stack with the auth (or home, if no PIN is set)
        // route before pushing the detail page. Backing out of the
        // detail page then lands on the PIN — re-entering the rest of
        // the app still requires authentication — instead of stranding
        // the user on a no-back-button screen.
        final hasPassword = AuthenticationService().hasPasswordSync();
        Get.offAllNamed(
          hasPassword ? AppRoutes.auth : AppRoutes.home,
        );
        // Schedule the push on the next frame so the offAllNamed route
        // transition has time to wire up — pushing synchronously can
        // miss the navigator stack and silently no-op.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.to<void>(() => LoyaltyCardDetailPage(card: card));
        });
      } else {
        await Get.to<void>(() => LoyaltyCardDetailPage(card: card));
      }
      return true;
    } catch (e) {
      debugPrint('WidgetDeepLinkHandler routing error: $e');
      return false;
    }
  }

  void dispose() {
    _clickSubscription?.cancel();
    _clickSubscription = null;
    _initialized = false;
  }
}
