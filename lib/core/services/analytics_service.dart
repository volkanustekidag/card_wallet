import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for event names + user property keys. Keeping them
/// here (rather than as inline string literals at call sites) prevents
/// "paywall_view" vs "paywall_viewed" drift across the codebase — a typo
/// silently splits a funnel into two events you can't join later in BigQuery.
class AnalyticsEvents {
  AnalyticsEvents._();

  // Lifecycle
  static const String appOpen = 'app_open';
  static const String onboardingComplete = 'onboarding_complete';

  // Cards
  static const String cardAdded = 'card_added';
  static const String cardLimitHit = 'card_limit_hit';

  // Paywall / purchase funnel
  static const String paywallViewed = 'paywall_viewed';
  static const String paywallPlanSelected = 'paywall_plan_selected';
  static const String purchaseSuccess = 'purchase_success';
  static const String purchaseCanceled = 'purchase_canceled';
  static const String purchaseFailed = 'purchase_failed';

  // Security
  static const String biometricEnabled = 'biometric_enabled';

  // Widget tutorial
  static const String widgetSetupShown = 'widget_setup_shown';
  static const String widgetSetupAcknowledged = 'widget_setup_acknowledged';
  static const String widgetSetupDeferred = 'widget_setup_deferred';

  // App store rate prompt — fired when we attempted to show the OS-native
  // review sheet. We can't tell whether the OS actually rendered it (Apple
  // and Play both rate-limit silently) but the attempt is the trigger
  // signal we have.
  static const String ratePromptShown = 'rate_prompt_shown';

  // Barcode / scanning
  static const String barcodeShown = 'barcode_shown';
  static const String scanStarted = 'scan_started';
  static const String scanSucceeded = 'scan_succeeded';
  static const String scanFailed = 'scan_failed';

  // Wallet export (Apple / Google Wallet)
  static const String walletExportAttempt = 'wallet_export_attempt';
  static const String walletExportSuccess = 'wallet_export_success';
  static const String walletExportFailed = 'wallet_export_failed';

  // Data
  static const String backupCreated = 'backup_created';
  static const String backupRestored = 'backup_restored';
  static const String cardCopied = 'card_copied';
  static const String cardShared = 'card_shared';
  static const String reminderEnabled = 'reminder_enabled';

  // Premium gates
  static const String paywallDismissed = 'paywall_dismissed';
  static const String premiumGateTapped = 'premium_gate_tapped';
}

class AnalyticsUserProps {
  AnalyticsUserProps._();

  static const String isPremium = 'is_premium';
  static const String cardCountTotal = 'card_count_total';
  static const String daysSinceInstall = 'days_since_install';
  static const String locale = 'app_locale';
  static const String creditCardCount = 'credit_card_count';
  static const String ibanCardCount = 'iban_card_count';
  static const String loyaltyCardCount = 'loyalty_card_count';
  static const String hasPin = 'has_pin';
}

/// Card type tag used across `card_added` and `card_limit_hit` so funnel
/// queries can split by type without parsing free-form strings.
class AnalyticsCardType {
  AnalyticsCardType._();

  static const String credit = 'credit';
  static const String iban = 'iban';
  static const String loyalty = 'loyalty';
}

/// Values for the `method` param of the scan_* events.
class AnalyticsScanMethod {
  AnalyticsScanMethod._();

  static const String camera = 'camera';
  static const String gallery = 'gallery';
  static const String qrCamera = 'qr_camera';
  static const String qrGallery = 'qr_gallery';
}

/// Values for the `format` param of card_shared.
class AnalyticsShareFormat {
  AnalyticsShareFormat._();

  static const String text = 'text';
  static const String image = 'image';
}

/// Thin wrapper around FirebaseAnalytics so the rest of the app never imports
/// the SDK directly. Failures are swallowed in release — analytics must never
/// take down a screen.
///
/// Privacy rule: parameters describe *what happened* (type, method, source,
/// provider, error key) — never card numbers, IBANs, barcodes or names.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // Resolved lazily so code paths that log can run in tests without Firebase.
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// When set, events go here instead of Firebase (tests).
  @visibleForTesting
  static void Function(String name, Map<String, Object>? params)? debugSink;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> setEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    final sink = debugSink;
    if (sink != null) return sink(name, params);
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  Future<void> logScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    final sink = debugSink;
    if (sink != null) return sink('user_property:$name', {'value': '$value'});
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  // ---------------------------------------------------------------------------
  // Typed helpers
  //
  // The bare logEvent() above is intentionally left exposed so one-off events
  // can be added without bouncing through here, but every call site for a
  // *funnel* event should use the helpers below — they enforce the parameter
  // shape and let the IDE rename them safely.
  // ---------------------------------------------------------------------------

  Future<void> logAppOpen() => logEvent(AnalyticsEvents.appOpen);

  Future<void> logOnboardingComplete() =>
      logEvent(AnalyticsEvents.onboardingComplete);

  Future<void> logCardAdded(String cardType) => logEvent(
        AnalyticsEvents.cardAdded,
        params: {'card_type': cardType},
      );

  Future<void> logCardLimitHit(String cardType) => logEvent(
        AnalyticsEvents.cardLimitHit,
        params: {'card_type': cardType},
      );

  /// [trigger] explains how the user landed here: `card_limit`, `settings`,
  /// `feature_gate`, etc. Empty/null trigger collapses to `unknown` so the
  /// param is always present.
  Future<void> logPaywallViewed({
    String? trigger,
    String? feature,
    String? cardType,
  }) =>
      logEvent(
        AnalyticsEvents.paywallViewed,
        params: {
          'trigger': trigger ?? 'unknown',
          if (feature != null) 'feature': feature,
          if (cardType != null) 'card_type': cardType,
        },
      );

  Future<void> logPaywallPlanSelected({
    required String productId,
    double? price,
    String? currency,
  }) =>
      logEvent(
        AnalyticsEvents.paywallPlanSelected,
        params: {
          'product_id': productId,
          if (price != null) 'price': price,
          if (currency != null) 'currency': currency,
        },
      );

  Future<void> logPurchaseSuccess({
    required String productId,
    double? price,
    String? currency,
  }) =>
      logEvent(
        AnalyticsEvents.purchaseSuccess,
        params: {
          'product_id': productId,
          if (price != null) 'value': price,
          if (currency != null) 'currency': currency,
        },
      );

  Future<void> logPurchaseCanceled(String productId) => logEvent(
        AnalyticsEvents.purchaseCanceled,
        params: {'product_id': productId},
      );

  Future<void> logPurchaseFailed(String productId) => logEvent(
        AnalyticsEvents.purchaseFailed,
        params: {'product_id': productId},
      );

  Future<void> logBiometricEnabled() =>
      logEvent(AnalyticsEvents.biometricEnabled);

  Future<void> logWidgetSetupShown(String platform) => logEvent(
        AnalyticsEvents.widgetSetupShown,
        params: {'platform': platform},
      );

  /// [source] is `time_based` (cold-start delayed check) or `milestone`
  /// (fired after a positive user action like the 3rd card added).
  /// [milestone] is only set for the milestone source.
  Future<void> logRatePromptShown({
    required String source,
    String? milestone,
  }) =>
      logEvent(
        AnalyticsEvents.ratePromptShown,
        params: {
          'source': source,
          if (milestone != null) 'milestone': milestone,
        },
      );

  Future<void> logWidgetSetupAcknowledged() =>
      logEvent(AnalyticsEvents.widgetSetupAcknowledged);

  Future<void> logWidgetSetupDeferred() =>
      logEvent(AnalyticsEvents.widgetSetupDeferred);

  /// [source]: `detail_page`, `detail_sheet` or `widget` (opened from the
  /// home/lock-screen widget while locked).
  Future<void> logBarcodeShown(String source) =>
      logEvent(AnalyticsEvents.barcodeShown, params: {'source': source});

  Future<void> logScanStarted({required String type, required String method}) =>
      logEvent(AnalyticsEvents.scanStarted,
          params: {'type': type, 'method': method});

  Future<void> logScanSucceeded({
    required String type,
    required String method,
  }) =>
      logEvent(AnalyticsEvents.scanSucceeded,
          params: {'type': type, 'method': method});

  Future<void> logScanFailed({required String type, required String method}) =>
      logEvent(AnalyticsEvents.scanFailed,
          params: {'type': type, 'method': method});

  /// [provider]: `apple` or `google`.
  Future<void> logWalletExportAttempt(String provider) => logEvent(
      AnalyticsEvents.walletExportAttempt,
      params: {'provider': provider});

  Future<void> logWalletExportSuccess(String provider) => logEvent(
      AnalyticsEvents.walletExportSuccess,
      params: {'provider': provider});

  /// [errorKey] is the translation key shown to the user (or `canceled` /
  /// `unknown`), never an exception message.
  Future<void> logWalletExportFailed({
    required String provider,
    required String errorKey,
  }) =>
      logEvent(AnalyticsEvents.walletExportFailed,
          params: {'provider': provider, 'error_key': errorKey});

  Future<void> logBackupCreated() => logEvent(AnalyticsEvents.backupCreated);

  Future<void> logBackupRestored() => logEvent(AnalyticsEvents.backupRestored);

  Future<void> logCardCopied(String cardType) =>
      logEvent(AnalyticsEvents.cardCopied, params: {'card_type': cardType});

  /// [format] ([AnalyticsShareFormat]) and [withQr] are set by the IBAN
  /// text/image share; other callers leave them out.
  Future<void> logCardShared({
    required String cardType,
    required bool masked,
    String? format,
    bool? withQr,
  }) =>
      logEvent(AnalyticsEvents.cardShared, params: {
        'card_type': cardType,
        'masked': masked ? 'true' : 'false',
        if (format != null) 'format': format,
        if (withQr != null) 'with_qr': withQr ? 'true' : 'false',
      });

  /// [kind]: `expiry` or `payment`.
  Future<void> logReminderEnabled(String kind) =>
      logEvent(AnalyticsEvents.reminderEnabled, params: {'kind': kind});

  Future<void> logPaywallDismissed({String? trigger, String? feature}) =>
      logEvent(AnalyticsEvents.paywallDismissed, params: {
        'trigger': trigger ?? 'unknown',
        if (feature != null) 'feature': feature,
      });

  Future<void> logPremiumGateTapped(String feature) => logEvent(
      AnalyticsEvents.premiumGateTapped,
      params: {'feature': feature});

  Future<void> setCardCounts({
    required int credit,
    required int iban,
    required int loyalty,
  }) async {
    await setUserProperty(AnalyticsUserProps.creditCardCount, '$credit');
    await setUserProperty(AnalyticsUserProps.ibanCardCount, '$iban');
    await setUserProperty(AnalyticsUserProps.loyaltyCardCount, '$loyalty');
  }

  Future<void> setHasPin(bool hasPin) =>
      setUserProperty(AnalyticsUserProps.hasPin, hasPin ? 'true' : 'false');

  Future<void> setIsPremium(bool isPremium) => setUserProperty(
      AnalyticsUserProps.isPremium, isPremium ? 'true' : 'false');

  Future<void> setCardCountTotal(int count) =>
      setUserProperty(AnalyticsUserProps.cardCountTotal, count.toString());

  Future<void> setDaysSinceInstall(int days) =>
      setUserProperty(AnalyticsUserProps.daysSinceInstall, days.toString());

  Future<void> setLocale(String localeTag) =>
      setUserProperty(AnalyticsUserProps.locale, localeTag);

  void _swallow(Object e, StackTrace s) {
    if (kDebugMode) {
      debugPrint('AnalyticsService error: $e\n$s');
    }
  }
}
