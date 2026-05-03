import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/services/premium_purchase_validator.dart';

/// Single source of truth for premium entitlement, IAP product loading and
/// subscription expiry handling.
///
/// Two flags drive entitlement:
///   * [_hasLifetime] — non-expiring lifetime purchase. Once true, premium
///     stays on forever.
///   * [_hasActiveSubscription] — derived from purchase stream events. Reset
///     to false on app foreground if a refresh round produces no active sub.
///
/// `isPremium` is the OR of the two. Production builds validate purchase
/// receipts through [PremiumPurchaseValidator] before granting entitlement.
class PremiumService {
  // ---------------------------------------------------------------------------
  // Product IDs
  // ---------------------------------------------------------------------------

  // New v2.0 product IDs (the ones to show on the paywall).
  static const String _androidMonthlyId =
      'com.volkan.walletapp.monthly_premium';
  static const String _androidYearlyV2Id =
      'com.volkan.walletapp.yearly_premium_v2';
  static const String _androidLifetimeId =
      'com.volkan.walletapp.lifetime_premium';

  static const String _iosMonthlyId = 'com.volkan.walletapp.monthly_premium';
  static const String _iosYearlyV2Id = 'com.volkan.walletapp.yearly_premium_v2';
  static const String _iosLifetimeId = 'com.volkan.walletapp.lifetime_premium';

  // Legacy v1 product IDs — recognised by restorePurchases but never offered
  // again to new buyers. Existing subscribers stay grandfathered.
  static const String _androidLegacyWeeklyId = 'com.volkan.walletapp.weekly';
  static const String _androidLegacyYearlyId = 'com.volkan.walletapp.yearly';
  static const String _iosLegacyWeeklyId =
      'com.volkan.walletapp.weekly_premium';
  static const String _iosLegacyYearlyId =
      'com.volkan.walletapp.yearly_premium';
  static const String _legacyLifetimeProductId = 'premium';

  static String get monthlyProductId =>
      Platform.isIOS ? _iosMonthlyId : _androidMonthlyId;
  static String get yearlyProductId =>
      Platform.isIOS ? _iosYearlyV2Id : _androidYearlyV2Id;
  static String get lifetimeProductId =>
      Platform.isIOS ? _iosLifetimeId : _androidLifetimeId;

  // Kept for backwards compat with code that still imports the old getters.
  static String get weeklyProductId =>
      Platform.isIOS ? _iosLegacyWeeklyId : _androidLegacyWeeklyId;
  static String get legacyYearlyProductId =>
      Platform.isIOS ? _iosLegacyYearlyId : _androidLegacyYearlyId;
  static String get legacyLifetimeProductId => _legacyLifetimeProductId;

  /// Active subscription product IDs (lifetime is in [_lifetimeProductIds]).
  static Set<String> get _subscriptionProductIds => {
        monthlyProductId,
        yearlyProductId,
      };

  static Set<String> get _legacySubscriptionProductIds => {
        weeklyProductId,
        legacyYearlyProductId,
      };

  static Set<String> get _lifetimeProductIds => {
        lifetimeProductId,
        _legacyLifetimeProductId,
      };

  /// All product IDs we want the store to query (paywall display).
  /// Includes both v2 + legacy IDs — the store may have one set or the
  /// other configured, and the controller's getters fall back across them.
  /// Whichever the store actually returns is what the user sees.
  static Set<String> get _productIdsToOffer => {
        monthlyProductId,
        yearlyProductId,
        lifetimeProductId,
        weeklyProductId,
        legacyYearlyProductId,
        _legacyLifetimeProductId,
      };

  /// All product IDs we accept on restore (current + legacy).
  static Set<String> get _allRecognisedProductIds => {
        ..._subscriptionProductIds,
        ..._legacySubscriptionProductIds,
        ..._lifetimeProductIds,
      };

  // ---------------------------------------------------------------------------
  // Storage keys
  // ---------------------------------------------------------------------------

  static const String _hasLifetimeKey = 'premium_has_lifetime';
  static const String _hasActiveSubscriptionKey =
      'premium_has_active_subscription';
  static const String _lastSubscriptionProductIdKey =
      'premium_last_subscription_product_id';
  static const String _lastVerifiedAtKey = 'premium_last_verified_at';
  // v1.x stored a single boolean here. Read once on first v2 launch so
  // existing paying users keep entitlement while restorePurchases() runs.
  static const String _legacyPremiumStatusKey = 'premium_status';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  static const _storage = FlutterSecureStorage();
  static final InAppPurchase _iap = InAppPurchase.instance;
  static const PremiumPurchaseValidator _purchaseValidator =
      PremiumPurchaseValidator();
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

  /// Sliding window during which a restore round can populate active
  /// subscriptions before we treat the absence of any as "expired".
  static const Duration _refreshWindow = Duration(seconds: 6);
  static DateTime? _activeRefreshUntil;
  static bool _sawActiveSubscriptionInWindow = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static Stream<bool> get premiumStatusStream =>
      _premiumStatusController.stream;
  static bool get isPremium => _hasLifetime || _hasActiveSubscription;
  static bool get hasLifetime => _hasLifetime;
  static bool get hasActiveSubscription => _hasActiveSubscription;
  static String? get lastSubscriptionProductId => _lastSubscriptionProductId;
  static DateTime? get lastVerifiedAt => _lastVerifiedAt;

  static Future<void> initialize() async {
    await _loadStoredState();

    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchaseUpdate(purchases)),
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[Premium] purchase stream error: $error'),
    );

    // Restore at startup so subscription state is verified.
    await refreshSubscriptionState();
  }

  /// Triggers a fresh round of `restorePurchases`, opening a window during
  /// which incoming purchase events count as "currently active". After the
  /// window closes, if no active subscription was reported and we don't have
  /// lifetime, the active-subscription flag is cleared.
  static Future<void> refreshSubscriptionState() async {
    try {
      _activeRefreshUntil = DateTime.now().add(_refreshWindow);
      _sawActiveSubscriptionInWindow = false;
      await _iap.restorePurchases();

      // Wait for the purchase stream to deliver events, then close the window.
      await Future.delayed(_refreshWindow);

      _activeRefreshUntil = null;
      if (!_sawActiveSubscriptionInWindow && !_hasLifetime) {
        if (_hasActiveSubscription) {
          debugPrint('[Premium] No active subscription returned by restore — '
              'downgrading to free.');
        }
        await _setSubscriptionActive(false);
      }
      await _markVerified();
    } catch (e) {
      debugPrint('[Premium] refreshSubscriptionState error: $e');
    }
  }

  static Future<bool> purchaseProduct(ProductDetails productDetails) async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      if (_lifetimeProductIds.contains(productDetails.id)) {
        return _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
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

  // Free tier: 2 of each kind. Tightened in I2 alongside making the
  // scanners free — scanners get users invested fast, the 2-card cap is
  // what funnels them toward premium.
  static const int maxCardsForFree = 2;
  static const int maxLoyaltyCardsForFree = 2;

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
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static Future<void> _loadStoredState() async {
    try {
      _hasLifetime = (await _storage.read(key: _hasLifetimeKey)) == 'true';
      _hasActiveSubscription =
          (await _storage.read(key: _hasActiveSubscriptionKey)) == 'true';
      _lastSubscriptionProductId =
          await _storage.read(key: _lastSubscriptionProductIdKey);
      final lastVerifiedStr = await _storage.read(key: _lastVerifiedAtKey);
      if (lastVerifiedStr != null) {
        _lastVerifiedAt = DateTime.tryParse(lastVerifiedStr);
      }
      await _migrateLegacyPremiumStatus();
    } catch (e) {
      debugPrint('[Premium] _loadStoredState error: $e');
    }
    _premiumStatusController.add(isPremium);
  }

  /// First v2 launch only: if the v1 `'premium_status'` flag is true and we
  /// have no v2 state, optimistically grant active-subscription so the user
  /// doesn't see a free-tier UI between launch and the first restore. If
  /// restore later confirms a lifetime receipt (legacy 'premium' product),
  /// [_handlePurchaseUpdate] promotes them to lifetime; if restore confirms
  /// nothing, [refreshSubscriptionState] resets the flag.
  static Future<void> _migrateLegacyPremiumStatus() async {
    if (_hasLifetime || _hasActiveSubscription) {
      // Already on v2 state — drop the legacy key if it lingers.
      await _storage.delete(key: _legacyPremiumStatusKey);
      return;
    }
    final legacy = await _storage.read(key: _legacyPremiumStatusKey);
    if (legacy != 'true') {
      return;
    }
    debugPrint('[Premium] migrating legacy premium_status=true → '
        'optimistic active-subscription pending restore');
    _hasActiveSubscription = true;
    await _storage.write(key: _hasActiveSubscriptionKey, value: 'true');
    await _storage.delete(key: _legacyPremiumStatusKey);
  }

  static Future<void> _setLifetime(bool value) async {
    if (_hasLifetime == value) return;
    _hasLifetime = value;
    try {
      await _storage.write(key: _hasLifetimeKey, value: value.toString());
    } catch (_) {}
    _premiumStatusController.add(isPremium);
  }

  static Future<void> _setSubscriptionActive(bool value,
      {String? productId}) async {
    final changed = _hasActiveSubscription != value ||
        (value && _lastSubscriptionProductId != productId);
    if (!changed) return;
    _hasActiveSubscription = value;
    if (value && productId != null) {
      _lastSubscriptionProductId = productId;
    }
    try {
      await _storage.write(
        key: _hasActiveSubscriptionKey,
        value: value.toString(),
      );
      if (value && productId != null) {
        await _storage.write(
          key: _lastSubscriptionProductIdKey,
          value: productId,
        );
      } else if (!value) {
        await _storage.delete(key: _lastSubscriptionProductIdKey);
      }
    } catch (_) {}
    _premiumStatusController.add(isPremium);
  }

  static Future<void> _markVerified() async {
    _lastVerifiedAt = DateTime.now();
    try {
      await _storage.write(
        key: _lastVerifiedAtKey,
        value: _lastVerifiedAt!.toIso8601String(),
      );
    } catch (_) {}
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
          break;
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!_allRecognisedProductIds.contains(details.productID)) {
            break;
          }
          final isLifetimeProduct = _lifetimeProductIds.contains(
            details.productID,
          );
          final validation = await _purchaseValidator.validate(
            details,
            isLifetimeProduct: isLifetimeProduct,
            isSubscriptionProduct:
                _subscriptionProductIds.contains(details.productID) ||
                    _legacySubscriptionProductIds.contains(details.productID),
          );
          if (!validation.isValid) {
            debugPrint(
              '[Premium] rejecting ${details.productID}: '
              '${validation.reason ?? 'invalid receipt'}',
            );
            break;
          }
          if (validation.grantsLifetime) {
            await _setLifetime(true);
          }
          if (validation.grantsActiveSubscription) {
            // Subscription event — count it as active for the current window.
            if (_activeRefreshUntil != null &&
                DateTime.now().isBefore(_activeRefreshUntil!)) {
              _sawActiveSubscriptionInWindow = true;
            }
            await _setSubscriptionActive(
              true,
              productId: details.productID,
            );
          }
          break;
      }

      if (details.pendingCompletePurchase) {
        await _iap.completePurchase(details);
      }
    }
  }
}
