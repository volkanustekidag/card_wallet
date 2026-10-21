import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show ReplacementMode;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/services/premium_entitlement_cache.dart';

enum PremiumPurchaseResult { success, pending, canceled, error }

/// Outcome of an explicit "Restore purchases" tap.
enum PremiumRestoreResult { restored, notFound, failed }

/// Premium entitlement is derived from the `in_app_purchase` plugin
/// (StoreKit / Play Billing). Every cold start re-asks the store via
/// [refreshSubscriptionState].
///
/// The last store-verified entitlement is cached in secure storage
/// ([PremiumEntitlementCache], 72 h TTL) and applied optimistically on cold
/// start so a paying user doesn't see locks or get bounced to the paywall
/// while the store answers (or while offline). The store's answer always
/// wins: if it reports no active purchase, premium is dropped and the cache
/// cleared.
///
/// Flags:
///   * [_hasLifetime] — grandfathered v1 lifetime non-consumable
///     (`_legacyLifetimeProductId`). No new sales; honoured on restore.
///   * [_hasActiveSubscription] — set from purchase stream events, cleared
///     if a refresh window closes with no active receipt.
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

  static InAppPurchase _iap = InAppPurchase.instance;
  static PremiumEntitlementCache _cache = PremiumEntitlementCache();
  static DateTime Function() _clock = DateTime.now;
  static bool Function() _isAndroid = () => Platform.isAndroid;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static final CreditCardService _creditCardService = CreditCardService();
  static final IbanCardService _ibanCardService = IbanCardService();
  static final LoyaltyCardService _loyaltyCardService = LoyaltyCardService();

  static bool _hasLifetime = false;
  static bool _lifetimeConfirmed = false;
  static bool _hasActiveSubscription = false;
  static String? _lastSubscriptionProductId;
  static PurchaseDetails? _activeSubscriptionPurchase;
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

  static Duration _refreshWindow = const Duration(seconds: 6);
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

  /// True when switching to another plan can happen in-app. Android needs
  /// the current purchase token (only known once the store has reported the
  /// purchase this session); iOS switches within the subscription group.
  static bool get canChangePlanInApp =>
      !_isAndroid() || _activeSubscriptionPurchase is GooglePlayPurchaseDetails;

  static Future<void> initialize() async {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchaseUpdate(purchases)),
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('[Premium] purchase stream error: $error'),
    );

    await _applyCachedEntitlement();
    _premiumStatusController.add(isPremium);
    await refreshSubscriptionState();
  }

  /// Optimistically restores the last verified entitlement if it is younger
  /// than [PremiumEntitlementCache.ttl].
  static Future<void> _applyCachedEntitlement() async {
    final cached = await _cache.read();
    if (cached == null ||
        !cached.isFresh(_clock(), PremiumEntitlementCache.ttl)) {
      return;
    }
    if (_lifetimeProductIds.contains(cached.productId)) {
      _hasLifetime = true;
    } else if (_subscriptionProductIds.contains(cached.productId)) {
      _hasActiveSubscription = true;
      _lastSubscriptionProductId = cached.productId;
    }
  }

  /// Asks the store for the user's current purchases. Events arrive via the
  /// [InAppPurchase.purchaseStream] inside a short window; if none confirm an
  /// active subscription or lifetime receipt by the end of the window,
  /// premium is dropped and the cached entitlement cleared.
  ///
  /// Store unavailable / restore failure keeps the current state (including
  /// an optimistic cached one) and reports [PremiumRestoreResult.failed].
  static Future<PremiumRestoreResult> refreshSubscriptionState() async {
    try {
      if (!await _iap.isAvailable()) return PremiumRestoreResult.failed;
      _activeRefreshUntil = _clock().add(_refreshWindow);
      _sawActiveSubscriptionInWindow = false;
      await AppLockService.guard(() => _iap.restorePurchases());

      await Future.delayed(_refreshWindow);

      _activeRefreshUntil = null;
      if (_hasLifetime && !_lifetimeConfirmed) {
        _setLifetime(false);
      }
      if (!_sawActiveSubscriptionInWindow && !_hasLifetime) {
        if (_hasActiveSubscription) {
          debugPrint('[Premium] No active subscription returned by restore — '
              'downgrading to free.');
        }
        _setSubscriptionActive(false);
      }
      if (!isPremium) await _cache.clear();
      _lastVerifiedAt = _clock();
      return isPremium
          ? PremiumRestoreResult.restored
          : PremiumRestoreResult.notFound;
    } catch (e) {
      // Offline / store unavailable: keep state from the previous round.
      debugPrint('[Premium] refreshSubscriptionState error: $e');
      _activeRefreshUntil = null;
      return PremiumRestoreResult.failed;
    }
  }

  /// Starts a store purchase. When the user already has a subscription and
  /// picks a different plan, Android gets a [ChangeSubscriptionParam] so Play
  /// replaces the old subscription instead of stacking a second one.
  static Future<bool> purchaseProduct(ProductDetails productDetails) async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;

      var purchaseParam = PurchaseParam(productDetails: productDetails);
      final isPlanSwitch = _hasActiveSubscription &&
          _subscriptionProductIds.contains(productDetails.id);
      if (isPlanSwitch) {
        if (productDetails.id == _lastSubscriptionProductId) return false;
        if (_isAndroid()) {
          final old = _activeSubscriptionPurchase;
          if (old is! GooglePlayPurchaseDetails) return false;
          purchaseParam = GooglePlayPurchaseParam(
            productDetails: productDetails,
            changeSubscriptionParam: ChangeSubscriptionParam(
              oldPurchaseDetails: old,
              replacementMode: ReplacementMode.withTimeProration,
            ),
          );
        }
      }
      final param = purchaseParam;
      return AppLockService.guard(
        () => _iap.buyNonConsumable(purchaseParam: param),
      );
    } catch (e) {
      debugPrint('[Premium] purchaseProduct error: $e');
      return false;
    }
  }

  static Future<PremiumRestoreResult> restorePurchases() =>
      refreshSubscriptionState();

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

  /// Swaps the store, cache and clock for tests.
  @visibleForTesting
  static void configureForTesting({
    required InAppPurchase iap,
    required PremiumEntitlementCache cache,
    DateTime Function()? clock,
    Duration refreshWindow = Duration.zero,
    bool isAndroid = false,
  }) {
    _subscription?.cancel();
    _subscription = null;
    _iap = iap;
    _cache = cache;
    _clock = clock ?? DateTime.now;
    _refreshWindow = refreshWindow;
    _isAndroid = () => isAndroid;
    _hasLifetime = false;
    _lifetimeConfirmed = false;
    _hasActiveSubscription = false;
    _lastSubscriptionProductId = null;
    _activeSubscriptionPurchase = null;
    _lastVerifiedAt = null;
    _activeRefreshUntil = null;
    _sawActiveSubscriptionInWindow = false;
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
      _activeSubscriptionPurchase = null;
    }
    _premiumStatusController.add(isPremium);
  }

  static Future<void> _handlePurchaseUpdate(
    List<PurchaseDetails> purchases,
  ) async {
    for (final details in purchases) {
      switch (details.status) {
        case PurchaseStatus.pending:
          // Ask to Buy / slow card / Play pending payment. The final
          // purchased event arrives later (maybe after a restart).
          _emitPurchaseResult(PremiumPurchaseResult.pending);
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
            _lifetimeConfirmed = true;
            _setLifetime(true);
          } else if (_subscriptionProductIds.contains(details.productID)) {
            if (_isInsideRefreshWindow()) {
              _sawActiveSubscriptionInWindow = true;
            }
            _activeSubscriptionPurchase = details;
            _setSubscriptionActive(true, productId: details.productID);
          }
          unawaited(_cache.save(CachedEntitlement(
            productId: details.productID,
            verifiedAt: _clock(),
          )));
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
    if (until == null) return false;
    // A zero-length test window is "inside" until it is explicitly closed.
    return !_clock().isAfter(until);
  }

  static bool _hasUsableVerificationData(PurchaseDetails details) {
    final local = details.verificationData.localVerificationData;
    final server = details.verificationData.serverVerificationData;
    return local.isNotEmpty || server.isNotEmpty;
  }
}
