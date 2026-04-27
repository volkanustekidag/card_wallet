import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/premium_service.dart';

class PremiumController extends GetxController {
  final RxBool _isPremium = false.obs;
  final RxBool _isLoading = false.obs;
  final RxList<ProductDetails> _availableProducts = <ProductDetails>[].obs;
  final RxInt _creditCardCount = 0.obs;
  final RxInt _ibanCardCount = 0.obs;
  bool _creditCountInitialized = false;
  bool _ibanCountInitialized = false;

  bool get isPremium => _isPremium.value;
  bool get isLoading => _isLoading.value;
  List<ProductDetails> get availableProducts => _availableProducts;
  RxList<ProductDetails> get availableProductsRx => _availableProducts;
  ProductDetails? get weeklyProduct =>
      _getProductById(PremiumService.weeklyProductId);
  ProductDetails? get yearlyProduct =>
      _getProductById(PremiumService.yearlyProductId);
  int get creditCardCount => _creditCardCount.value;
  int get ibanCardCount => _ibanCardCount.value;

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

    PremiumService.premiumStatusStream.listen((status) {
      _isPremium.value = status;
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

  Future<bool> purchase(ProductDetails product) async {
    _isLoading.value = true;
    try {
      final success = await PremiumService.purchaseProduct(product);
      return success;
    } catch (e) {
      debugPrint('Error purchasing premium: $e');
      return false;
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

  int get maxCardsForFree => PremiumService.maxCardsForFree;

  Future<int> getStoredCardCount(CardLimitType type) async {
    if (type == CardLimitType.credit) {
      if (_creditCountInitialized) {
        return creditCardCount;
      }
      final count = await PremiumService.getStoredCreditCardCount();
      _creditCardCount.value = count;
      _creditCountInitialized = true;
      return count;
    }

    if (_ibanCountInitialized) {
      return ibanCardCount;
    }
    final count = await PremiumService.getStoredIbanCardCount();
    _ibanCardCount.value = count;
    _ibanCountInitialized = true;
    return count;
  }

  void setCardCounts({required int creditCount, required int ibanCount}) {
    _creditCardCount.value = creditCount;
    _ibanCardCount.value = ibanCount;
    _creditCountInitialized = true;
    _ibanCountInitialized = true;
  }

  @override
  void onClose() {
    PremiumService.dispose();
    super.onClose();
  }
}
