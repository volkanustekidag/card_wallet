import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/premium_service.dart';

class PremiumController extends GetxController {
  final RxBool _isPremium = false.obs;
  final RxBool _isLoading = false.obs;
  final RxList<ProductDetails> _availableProducts = <ProductDetails>[].obs;
  final RxInt _creditCardCount = 0.obs;
  final RxInt _ibanCardCount = 0.obs;
  final RxInt _loyaltyCardCount = 0.obs;
  bool _creditCountInitialized = false;
  bool _ibanCountInitialized = false;
  bool _loyaltyCountInitialized = false;

  bool get isPremium => _isPremium.value;
  bool get isLoading => _isLoading.value;
  List<ProductDetails> get availableProducts => _availableProducts;
  RxList<ProductDetails> get availableProductsRx => _availableProducts;
  ProductDetails? get weeklyProduct =>
      _getProductById(PremiumService.weeklyProductId);
  ProductDetails? get monthlyProduct =>
      _getProductById(PremiumService.monthlyProductId);
  ProductDetails? get yearlyProduct =>
      _getProductById(PremiumService.yearlyProductId);
  int get creditCardCount => _creditCardCount.value;
  int get ibanCardCount => _ibanCardCount.value;
  int get loyaltyCardCount => _loyaltyCardCount.value;

  @override
  void onInit() {
    super.onInit();
    _initializePremium();
  }

  Future<void> _initializePremium() async {
    _isLoading.value = true;

    // PremiumService is initialized in main.dart so the UI sees the
    // correct premium state on first frame. We just sync status here
    // and start listening for runtime changes.
    _isPremium.value = PremiumService.isPremium;
    unawaited(AnalyticsService.instance.setIsPremium(_isPremium.value));

    PremiumService.premiumStatusStream.listen((status) {
      _isPremium.value = status;
      unawaited(AnalyticsService.instance.setIsPremium(status));
      update();
    });

    await _loadPremiumProducts();

    _isLoading.value = false;
  }

  Future<void> _loadPremiumProducts() async {
    try {
      debugPrint('🔄 [PremiumController] Loading premium products...');
      final products = await PremiumService.getPremiumProductDetails();
      _availableProducts.assignAll(products);
      debugPrint(
          '🔄 [PremiumController] Loaded ${products.length} premium products.');
    } catch (e) {
      debugPrint('❌ [PremiumController] Error loading premium product: $e');
    }
  }

  ProductDetails? _getProductById(String productId) {
    try {
      return _availableProducts
          .firstWhere((product) => product.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Returns the real store outcome — completes only after the purchase
  /// stream confirms success / cancel / error (or a safety timeout fires).
  /// Loading state stays on for the whole window so the paywall blocks
  /// double-taps and we don't show success UI before the store confirms.
  Future<PremiumPurchaseResult> purchase(ProductDetails product) async {
    _isLoading.value = true;

    final completer = Completer<PremiumPurchaseResult>();
    StreamSubscription<PremiumPurchaseResult>? sub;
    Timer? timeout;

    void finish(PremiumPurchaseResult result) {
      if (completer.isCompleted) return;
      sub?.cancel();
      timeout?.cancel();
      completer.complete(result);
    }

    sub = PremiumService.purchaseResultStream.listen(finish);
    timeout = Timer(const Duration(seconds: 90), () {
      finish(PremiumPurchaseResult.error);
    });

    try {
      final dispatched = await PremiumService.purchaseProduct(product);
      if (!dispatched) {
        finish(PremiumPurchaseResult.error);
      }
    } catch (e) {
      debugPrint('Error purchasing premium: $e');
      finish(PremiumPurchaseResult.error);
    }

    try {
      return await completer.future;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> restorePurchases() async {
    _isLoading.value = true;
    try {
      await PremiumService.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Card limit methods
  bool canAddMoreCreditCards(int currentCount) {
    return PremiumService.canAddMoreCreditCards(currentCount);
  }

  bool canAddMoreIbanCards(int currentCount) {
    return PremiumService.canAddMoreIbanCards(currentCount);
  }

  bool canAddMoreLoyaltyCards(int currentCount) {
    return PremiumService.canAddMoreLoyaltyCards(currentCount);
  }

  int get maxCardsForFree => PremiumService.maxCardsForFree;
  int get maxLoyaltyCardsForFree => PremiumService.maxLoyaltyCardsForFree;

  Future<int> getStoredCardCount(CardLimitType type) async {
    switch (type) {
      case CardLimitType.credit:
        if (_creditCountInitialized) return creditCardCount;
        final count = await PremiumService.getStoredCreditCardCount();
        _creditCardCount.value = count;
        _creditCountInitialized = true;
        return count;
      case CardLimitType.iban:
        if (_ibanCountInitialized) return ibanCardCount;
        final count = await PremiumService.getStoredIbanCardCount();
        _ibanCardCount.value = count;
        _ibanCountInitialized = true;
        return count;
      case CardLimitType.loyalty:
        if (_loyaltyCountInitialized) return loyaltyCardCount;
        final count = await PremiumService.getStoredLoyaltyCardCount();
        _loyaltyCardCount.value = count;
        _loyaltyCountInitialized = true;
        return count;
    }
  }

  void setCardCounts({
    required int creditCount,
    required int ibanCount,
    int? loyaltyCount,
  }) {
    _creditCardCount.value = creditCount;
    _ibanCardCount.value = ibanCount;
    _creditCountInitialized = true;
    _ibanCountInitialized = true;
    if (loyaltyCount != null) {
      _loyaltyCardCount.value = loyaltyCount;
      _loyaltyCountInitialized = true;
    }
  }

  @override
  void onClose() {
    PremiumService.dispose();
    super.onClose();
  }
}
