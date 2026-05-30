import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';

enum PremiumPurchaseResult { success, canceled, error }

/// Premium entitlement is process-scoped and derived purely from the
/// `in_app_purchase` plugin (StoreKit / Play Billing). Nothing is persisted
/// to disk — every cold start re-asks the store via [refreshSubscriptionState]
/// so a rooted device can't grant itself premium by editing local storage.
///
/// In-memory flags:
///   * [_hasLifetime] — grandfathered v1 lifetime non-consumable
///     (`_legacyLifetimeProductId`). No new sales; honoured on restore.
///   * [_hasActiveSubscription] — set from purchase stream events inside a
///     refresh window, cleared if the window closes with no active receipt.
class PremiumService {
  // ---------------------------------------------------------------------------
  // Product IDs
  // ---------------------------------------------------------------------------

  static const String _iosWeeklyId = 'com.volkan.walletapp.weekly_premium';
  static const String _androidWeeklyId = 'com.volkan.walletapp.weekly';

  static const String _monthlyId = 'com.volkan.walletapp.monthly_premium';

  static const String _iosYearlyId = 'com.volkan.walletapp.yearly_premium';
  static const String _androidYearlyId = 'com.volkan.walletapp.yearly';

  static const String _legacyLifetimeProductId = 'premium';

  static String get weeklyProductId =>
      Platform.isIOS ? _iosWeeklyId : _androidWeeklyId;
  static String get monthlyProductId => _monthlyId;
  static String get yearlyProductId =>
      Platform.isIOS ? _iosYearlyId : _androidYearlyId;
  static String get legacyLifetimeProductId => _legacyLifetimeProductId;

  static Set<String> get _subscriptionProductIds => {
        weeklyProductId,
        monthlyProductId,
        yearlyProductId,
      };

  static Set<String> get _lifetimeProductIds => {
        _legacyLifetimeProductId,
      };

  static Set<String> get _productIdsToOffer => {
        weeklyProductId,
        monthlyProductId,
        yearlyProductId,
      };

  static Set<String> get _allRecognisedProductIds => {
        ..._subscriptionProductIds,
        ..._lifetimeProductIds,
      };

  // ---------------------------------------------------------------------------
  // State (in-memory only — never persisted)
  // ---------------------------------------------------------------------------

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static final CreditCardService _creditCardService = CreditCardService();
  static final IbanCardService _ibanCardService = IbanCardService();
  static final LoyaltyCardService _loyaltyCardService = LoyaltyCardService();

  static bool _hasLifetime = false;
  static bool _hasActiveSubscription = false;
  static String? _lastSubscriptionProductId;
  static DateTime? _lastVerifiedAt;

  static final StreamController<bool> _premiumStatusController =
      StreamController<bool>.broadcast();

  /// Emits one event per outcome of an active store transaction
  /// (purchased / canceled / error). Restore-driven `restored` events are
  /// deliberately skipped here so the explicit "Restore" UI controls its
  /// own feedback.
  static final StreamController<PremiumPurchaseResult>
      _purchaseResultController =
      StreamController<PremiumPurchaseResult>.broadcast();

  static const Duration _refreshWindow = Duration(seconds: 6);
  static DateTime? _activeRefreshUntil;
  static bool _sawActiveSubscriptionInWindow = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static Stream<bool> get premiumStatusStream =>
      _premiumStatusController.stream;
  static Stream<PremiumPurchaseResult> get purchaseResultStream =>
      _purchaseResultController.stream;
  static bool get isPremium => _hasLifetime || _hasActiveSubscription;
  static bool get hasLifetime => _hasLifetime;
  static bool get hasActiveSubscription => _hasActiveSubscription;
  static String? get lastSubscriptionProductId => _lastSubscriptionProductId;
  static DateTime? get lastVerifiedAt => _lastVerifiedAt;

  static Future<void> initialize() async {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchaseUpdate(purchases)),
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[Premium] purchase stream error: $error'),
    );

    // Cold-start defaults to free; restore round below promotes the user
    // back to premium if the store says so.
    _premiumStatusController.add(isPremium);
    await refreshSubscriptionState();
  }

  /// Asks the store for the user's current purchases. Events arrive via the
  /// [InAppPurchase.purchaseStream] inside a short window; if none confirm an
  /// active subscription (and no lifetime receipt) by the end of the window,
  /// the active flag is cleared.
  static Future<void> refreshSubscriptionState() async {
    try {
      _activeRefreshUntil = DateTime.now().add(_refreshWindow);
      _sawActiveSubscriptionInWindow = false;
      await _iap.restorePurchases();

      await Future.delayed(_refreshWindow);

      _activeRefreshUntil = null;
      if (!_sawActiveSubscriptionInWindow && !_hasLifetime) {
        if (_hasActiveSubscription) {
          debugPrint('[Premium] No active subscription returned by restore — '
              'downgrading to free.');
        }
        _setSubscriptionActive(false);
      }
      _lastVerifiedAt = DateTime.now();
    } catch (e) {
      // Offline / store unavailable: keep in-memory state from the previous
      // successful round. Process restart will force a fresh check.
      debugPrint('[Premium] refreshSubscriptionState error: $e');
    }
  }

  static Future<bool> purchaseProduct(ProductDetails productDetails) async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      return _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[Premium] purchaseProduct error: $e');
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    await refreshSubscriptionState();
  }

  static Future<List<ProductDetails>> getPremiumProductDetails() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return [];

      final response = await _iap.queryProductDetails(_productIdsToOffer);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[Premium] product IDs not found: ${response.notFoundIDs}');
      }
      return response.productDetails;
    } catch (e) {
      debugPrint('[Premium] getPremiumProductDetails error: $e');
      return [];
    }
  }

  static const int maxCardsForFree = 2;
  static const int maxLoyaltyCardsForFree = 5;

  static bool canAddMoreCreditCards(int currentCount) {
    if (isPremium) return true;
    return currentCount < maxCardsForFree;
  }

  static bool canAddMoreIbanCards(int currentCount) {
    if (isPremium) return true;
    return currentCount < maxCardsForFree;
  }

  static bool canAddMoreLoyaltyCards(int currentCount) {
    if (isPremium) return true;
    return currentCount < maxLoyaltyCardsForFree;
  }

  static Future<int> getStoredCreditCardCount() async {
    try {
      await _creditCardService.openBox();
      final cards = await _creditCardService.getAllCreditCards();
      return cards.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getStoredIbanCardCount() async {
    try {
      await _ibanCardService.openBox();
      final cards = await _ibanCardService.getAllIbanCards();
      return cards.length;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getStoredLoyaltyCardCount() async {
    try {
      await _loyaltyCardService.openBox();
      final cards = await _loyaltyCardService.getAllLoyaltyCards();
      return cards.length;
    } catch (_) {
      return 0;
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _premiumStatusController.close();
    _purchaseResultController.close();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static void _setLifetime(bool value) {
    if (_hasLifetime == value) return;
    _hasLifetime = value;
    _premiumStatusController.add(isPremium);
  }

  static void _setSubscriptionActive(bool value, {String? productId}) {
    final changed = _hasActiveSubscription != value ||
        (value && _lastSubscriptionProductId != productId);
    if (!changed) return;
    _hasActiveSubscription = value;
    if (value && productId != null) {
      _lastSubscriptionProductId = productId;
    } else if (!value) {
      _lastSubscriptionProductId = null;
    }
    _premiumStatusController.add(isPremium);
  }

  static Future<void> _handlePurchaseUpdate(
    List<PurchaseDetails> purchases,
  ) async {
    for (final details in purchases) {
      switch (details.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          debugPrint('[Premium] purchase error for ${details.productID}: '
              '${details.error?.message}');
          _emitPurchaseResult(PremiumPurchaseResult.error);
          break;
        case PurchaseStatus.canceled:
          _emitPurchaseResult(PremiumPurchaseResult.canceled);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!_allRecognisedProductIds.contains(details.productID)) {
            break;
          }
          // StoreKit sometimes reports a fresh auto-renewable subscription
          // purchase as `.restored` (common in sandbox when the same Apple ID
          // has bought before). Outside the programmatic restore window any
          // event — purchased or restored — is the result of an active buy
          // attempt, so the paywall is waiting for a result either way.
          final isActiveBuyResult = details.status == PurchaseStatus.purchased ||
              !_isInsideRefreshWindow();
          if (!_hasUsableVerificationData(details)) {
            debugPrint('[Premium] rejecting ${details.productID}: '
                'empty receipt verification data');
            if (isActiveBuyResult) {
              _emitPurchaseResult(PremiumPurchaseResult.error);
            }
            break;
          }
          final isLifetimeProduct =
              _lifetimeProductIds.contains(details.productID);
          if (isLifetimeProduct) {
            _setLifetime(true);
          } else if (_subscriptionProductIds.contains(details.productID)) {
            if (_isInsideRefreshWindow()) {
              _sawActiveSubscriptionInWindow = true;
            }
            _setSubscriptionActive(true, productId: details.productID);
          }
          if (isActiveBuyResult) {
            _emitPurchaseResult(PremiumPurchaseResult.success);
          }
          break;
      }

      if (details.pendingCompletePurchase) {
        await _iap.completePurchase(details);
      }
    }
  }

  static void _emitPurchaseResult(PremiumPurchaseResult result) {
    if (_purchaseResultController.isClosed) return;
    _purchaseResultController.add(result);
  }

  static bool _isInsideRefreshWindow() {
    final until = _activeRefreshUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  static bool _hasUsableVerificationData(PurchaseDetails details) {
    final local = details.verificationData.localVerificationData;
    final server = details.verificationData.serverVerificationData;
    return local.isNotEmpty || server.isNotEmpty;
  }
}
