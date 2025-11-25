import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wallet_app/core/data/services/admob_service.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/premium_service.dart';

class PremiumController extends GetxController {
  final RxBool _isPremium = false.obs;
  final RxBool _isLoading = false.obs;
  final Rx<ProductDetails?> _premiumProduct = Rx<ProductDetails?>(null);
  bool _skipNextInterstitial = false;

  bool get isPremium => _isPremium.value;
  bool get isLoading => _isLoading.value;
  ProductDetails? get premiumProduct => _premiumProduct.value;
  bool get shouldSkipInterstitial => _skipNextInterstitial;

  @override
  void onInit() {
    super.onInit();
    _initializePremium();
  }

  Future<void> _initializePremium() async {
    _isLoading.value = true;
    
    // Initialize premium service
    await PremiumService.initialize();
    
    // Set initial premium status
    _isPremium.value = PremiumService.isPremium;
    
    // Listen to premium status changes
    PremiumService.premiumStatusStream.listen((status) {
      _isPremium.value = status;
      update(); // GetBuilder için güncelleme tetikle
    });
    
    // Load premium product details
    await _loadPremiumProduct();
    
    _isLoading.value = false;
  }

  Future<void> _loadPremiumProduct() async {
    try {
      print('🔄 [PremiumController] Loading premium product...');
      final product = await PremiumService.getPremiumProductDetails();
      _premiumProduct.value = product;
      print('🔄 [PremiumController] Premium product result: ${product?.id ?? "NULL"}');
    } catch (e) {
      print('❌ [PremiumController] Error loading premium product: $e');
    }
  }

  Future<bool> purchasePremium() async {
    _isLoading.value = true;
    try {
      final success = await PremiumService.purchasePremium();
      return success;
    } catch (e) {
      print('Error purchasing premium: $e');
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
      print('Error restoring purchases: $e');
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

  Future<bool> requestRewardedSlot(CardLimitType type) async {
    try {
      final rewarded = await AdMobService.showRewardedAd();
      if (rewarded) {
        _skipNextInterstitial = true;
      }
      return rewarded;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  Future<void> showInterstitialIfNeeded() async {
    if (isPremium) return;

    if (_skipNextInterstitial) {
      _skipNextInterstitial = false;
      return;
    }

    await AdMobService.showInterstitialAd();
  }

  Future<int> getStoredCardCount(CardLimitType type) async {
    if (type == CardLimitType.credit) {
      return await PremiumService.getStoredCreditCardCount();
    }
    return await PremiumService.getStoredIbanCardCount();
  }

  @override
  void onClose() {
    PremiumService.dispose();
    super.onClose();
  }
}
