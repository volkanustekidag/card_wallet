import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';

class PremiumService {
  // Android product IDs
  static const String _androidWeeklyProductId = 'com.volkan.walletapp.weekly';
  static const String _androidYearlyProductId = 'com.volkan.walletapp.yearly';

  // iOS product IDs
  static const String _iosWeeklyProductId = 'com.volkan.walletapp.weekly_premium';
  static const String _iosYearlyProductId = 'com.volkan.walletapp.yearly_premium';

  // Platform-specific product IDs
  static String get weeklyProductId => Platform.isIOS ? _iosWeeklyProductId : _androidWeeklyProductId;
  static String get yearlyProductId => Platform.isIOS ? _iosYearlyProductId : _androidYearlyProductId;

  static const String _legacyLifetimeProductId = 'premium';

  static Set<String> get _subscriptionProductIds => {
    weeklyProductId,
    yearlyProductId,
  };

  static Set<String> get _allSupportedProductIds => {
    weeklyProductId,
    yearlyProductId,
    _legacyLifetimeProductId,
  };
  static const String _premiumStatusKey = 'premium_status';
  static const _storage = FlutterSecureStorage();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static late StreamSubscription<List<PurchaseDetails>> _subscription;
  static final CreditCardService _creditCardService = CreditCardService();
  static final IbanCardService _ibanCardService = IbanCardService();

  static bool _isPremium = false;
  static final StreamController<bool> _premiumStatusController =
      StreamController<bool>.broadcast();

  // Premium status stream
  static Stream<bool> get premiumStatusStream =>
      _premiumStatusController.stream;
  static bool get isPremium => _isPremium;

  static Future<void> initialize() async {
    // Load saved premium status
    await _loadPremiumStatus();

    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Restore purchases on app start
    await restorePurchases();
  }

  static Future<void> _loadPremiumStatus() async {
    try {
      final premiumStatus = await _storage.read(key: _premiumStatusKey);
      _isPremium = premiumStatus == 'true';
      _premiumStatusController.add(_isPremium);
      if (_isPremium) {
        print(
            '📦 [Premium] Loaded stored premium status (likely legacy lifetime fallback). Waiting for store validation.');
      } else {
        print('📦 [Premium] No stored premium status found.');
      }
    } catch (e) {
      _isPremium = false;
      _premiumStatusController.add(_isPremium);
    }
  }

  static Future<void> _savePremiumStatus(bool status) async {
    try {
      await _storage.write(key: _premiumStatusKey, value: status.toString());
      _isPremium = status;
      _premiumStatusController.add(_isPremium);
    } catch (e) {}
  }

  static Future<bool> purchaseProduct(ProductDetails productDetails) async {
    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool success =
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {}
  }

  static void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchase or restore
        if (_allSupportedProductIds.contains(purchaseDetails.productID)) {
          if (purchaseDetails.productID == _legacyLifetimeProductId) {
            print(
                '🔁 [Premium] Detected legacy lifetime purchase (${purchaseDetails.productID}). Keeping premium unlocked.');
          }
          _savePremiumStatus(true);
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  static Future<List<ProductDetails>> getPremiumProductDetails() async {
    try {
      print('🔍 [Premium] Checking if IAP is available...');
      final bool available = await _iap.isAvailable();
      print('🔍 [Premium] IAP available: $available');

      if (!available) {
        print('❌ [Premium] IAP not available on this device');
        return [];
      }

      print(
          '🔍 [Premium] Querying products: ${_subscriptionProductIds.join(", ")}');

      final ProductDetailsResponse response =
          await _iap.queryProductDetails(_subscriptionProductIds);

      print('🔍 [Premium] Products found: ${response.productDetails.length}');
      print('🔍 [Premium] Not found IDs: ${response.notFoundIDs}');

      if (response.productDetails.isEmpty) {
        print('❌ [Premium] No products found');
        return [];
      }

      for (final product in response.productDetails) {
        print('✅ [Premium] Product loaded: ${product.id} - ${product.price}');
      }
      return response.productDetails;
    } catch (e) {
      print('❌ [Premium] Error loading product: $e');
      return [];
    }
  }

  // Card limit methods
  static const int maxCardsForFree = 1;

  static bool canAddMoreCreditCards(int currentCount) {
    if (_isPremium) return true;
    return currentCount < maxCardsForFree;
  }

  static bool canAddMoreIbanCards(int currentCount) {
    if (_isPremium) return true;
    return currentCount < maxCardsForFree;
  }

  static void dispose() {
    _subscription.cancel();
    _premiumStatusController.close();
  }

  static Future<int> getStoredCreditCardCount() async {
    try {
      await _creditCardService.openBox();
      final cards = await _creditCardService.getAllCreditCards();
      return cards.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> getStoredIbanCardCount() async {
    try {
      await _ibanCardService.openBox();
      final cards = await _ibanCardService.getAllIbanCards();
      return cards.length;
    } catch (e) {
      return 0;
    }
  }
}
