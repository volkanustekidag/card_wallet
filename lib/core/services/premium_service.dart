import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PremiumService {
  static const String _premiumProductId = 'premium';
  static const String _premiumStatusKey = 'premium_status';
  static const _storage = FlutterSecureStorage();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static late StreamSubscription<List<PurchaseDetails>> _subscription;

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

  static Future<bool> purchasePremium() async {
    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        return false;
      }

      const Set<String> productIds = {_premiumProductId};
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);

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
        if (purchaseDetails.productID == _premiumProductId) {
          _savePremiumStatus(true);
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  static Future<ProductDetails?> getPremiumProductDetails() async {
    try {
      final bool available = await _iap.isAvailable();
      if (!available) return null;

      const Set<String> productIds = {_premiumProductId};
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(productIds);

      if (response.productDetails.isNotEmpty) {
        return response.productDetails.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Card limit methods
  static const int maxCardsForFree = 3;

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
}
