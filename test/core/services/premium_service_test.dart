import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:wallet_app/core/services/premium_entitlement_cache.dart';
import 'package:wallet_app/core/services/premium_service.dart';

/// In-memory stand-in for the store plugin.
class FakeInAppPurchase implements InAppPurchase {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  bool throwOnRestore = false;
  List<PurchaseDetails> restoreResult = [];
  final bought = <PurchaseParam>[];
  final completed = <PurchaseDetails>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (throwOnRestore) throw Exception('offline');
    if (restoreResult.isNotEmpty) controller.add(restoreResult);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought.add(purchaseParam);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryEntitlementCache extends PremiumEntitlementCache {
  CachedEntitlement? value;

  @override
  Future<CachedEntitlement?> read() async => value;

  @override
  Future<void> save(CachedEntitlement entitlement) async => value = entitlement;

  @override
  Future<void> clear() async => value = null;
}

PurchaseVerificationData _verification() => PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'token-123',
      source: 'test',
    );

PurchaseDetails _purchase(
  String productId,
  PurchaseStatus status, {
  bool pendingComplete = false,
}) =>
    PurchaseDetails(
      productID: productId,
      verificationData: _verification(),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = pendingComplete;

ProductDetails _product(String id) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: '1',
      rawPrice: 1,
      currencyCode: 'USD',
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeInAppPurchase iap;
  late MemoryEntitlementCache cache;
  late DateTime now;

  void configure({bool isAndroid = false}) {
    PremiumService.configureForTesting(
      iap: iap,
      cache: cache,
      clock: () => now,
      isAndroid: isAndroid,
    );
  }

  setUp(() {
    iap = FakeInAppPurchase();
    cache = MemoryEntitlementCache();
    now = DateTime(2026, 10, 21, 12);
    configure();
  });

  group('entitlement cache', () {
    test('fresh cache shows premium before the store answers', () async {
      cache.value = CachedEntitlement(
        productId: PremiumService.yearlyProductId,
        verifiedAt: now.subtract(const Duration(hours: 10)),
      );
      iap.available = false; // store unreachable (offline)

      await PremiumService.initialize();

      expect(PremiumService.isPremium, isTrue);
      expect(cache.value, isNotNull);
    });

    test('expired cache (older than 72 h) is ignored', () async {
      cache.value = CachedEntitlement(
        productId: PremiumService.yearlyProductId,
        verifiedAt: now.subtract(const Duration(hours: 73)),
      );
      iap.available = false;

      await PremiumService.initialize();

      expect(PremiumService.isPremium, isFalse);
    });

    test('store "no active subscription" drops premium and clears cache',
        () async {
      cache.value = CachedEntitlement(
        productId: PremiumService.monthlyProductId,
        verifiedAt: now.subtract(const Duration(hours: 1)),
      );

      await PremiumService.initialize();

      expect(PremiumService.isPremium, isFalse);
      expect(cache.value, isNull);
    });

    test('restore failure keeps the cached entitlement', () async {
      cache.value = CachedEntitlement(
        productId: PremiumService.monthlyProductId,
        verifiedAt: now.subtract(const Duration(hours: 1)),
      );
      iap.throwOnRestore = true;

      await PremiumService.initialize();

      expect(PremiumService.isPremium, isTrue);
    });

    test('a verified purchase is written to the cache', () async {
      await PremiumService.initialize();
      iap.controller.add([
        _purchase(PremiumService.yearlyProductId, PurchaseStatus.purchased),
      ]);
      await _settle();

      expect(PremiumService.isPremium, isTrue);
      expect(cache.value?.productId, PremiumService.yearlyProductId);
      expect(cache.value?.verifiedAt, now);
    });
  });

  group('restore', () {
    test('reports restored when the store returns an active plan', () async {
      await PremiumService.initialize();
      iap.restoreResult = [
        _purchase(PremiumService.weeklyProductId, PurchaseStatus.restored),
      ];

      final result = await PremiumService.restorePurchases();

      expect(result, PremiumRestoreResult.restored);
      expect(PremiumService.hasActiveSubscription, isTrue);
    });

    test('reports notFound when nothing comes back', () async {
      await PremiumService.initialize();
      expect(
        await PremiumService.restorePurchases(),
        PremiumRestoreResult.notFound,
      );
    });

    test('reports failed when the store is unavailable', () async {
      await PremiumService.initialize();
      iap.available = false;
      expect(
        await PremiumService.restorePurchases(),
        PremiumRestoreResult.failed,
      );
    });
  });

  group('purchase stream', () {
    test('pending purchases emit pending instead of timing out', () async {
      await PremiumService.initialize();
      final results = <PremiumPurchaseResult>[];
      final sub = PremiumService.purchaseResultStream.listen(results.add);

      iap.controller.add([
        _purchase(PremiumService.monthlyProductId, PurchaseStatus.pending),
      ]);
      await _settle();

      expect(results, [PremiumPurchaseResult.pending]);
      expect(PremiumService.isPremium, isFalse);
      await sub.cancel();
    });

    test('completePurchase is called for pending-complete purchases',
        () async {
      await PremiumService.initialize();
      final details = _purchase(
        PremiumService.monthlyProductId,
        PurchaseStatus.purchased,
        pendingComplete: true,
      );
      iap.controller.add([details]);
      await _settle();

      expect(iap.completed, [details]);
    });

    test('purchases with empty receipts are rejected', () async {
      await PremiumService.initialize();
      iap.controller.add([
        PurchaseDetails(
          productID: PremiumService.monthlyProductId,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'test',
          ),
          transactionDate: '0',
          status: PurchaseStatus.purchased,
        ),
      ]);
      await _settle();

      expect(PremiumService.isPremium, isFalse);
    });
  });

  group('plan change', () {
    test('Android switch passes ChangeSubscriptionParam', () async {
      configure(isAndroid: true);
      await PremiumService.initialize();
      final old = GooglePlayPurchaseDetails(
        productID: PremiumService.monthlyProductId,
        verificationData: _verification(),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
        billingClientPurchase: PurchaseWrapper(
          orderId: 'o',
          packageName: 'com.volkan.wallet_app',
          purchaseTime: 0,
          purchaseToken: 'token-123',
          signature: 's',
          products: [PremiumService.monthlyProductId],
          isAutoRenewing: true,
          originalJson: '{}',
          isAcknowledged: true,
          purchaseState: PurchaseStateWrapper.purchased,
        ),
      );
      iap.controller.add([old]);
      await _settle();
      expect(PremiumService.canChangePlanInApp, isTrue);

      final ok = await PremiumService.purchaseProduct(
        _product(PremiumService.yearlyProductId),
      );

      expect(ok, isTrue);
      final param = iap.bought.single;
      expect(param, isA<GooglePlayPurchaseParam>());
      final change = (param as GooglePlayPurchaseParam).changeSubscriptionParam;
      expect(change?.oldPurchaseDetails, same(old));
      expect(change?.replacementMode, ReplacementMode.withTimeProration);
    });

    test('Android switch without the old purchase is refused', () async {
      configure(isAndroid: true);
      cache.value = CachedEntitlement(
        productId: PremiumService.monthlyProductId,
        verifiedAt: now,
      );
      iap.throwOnRestore = true; // keep the optimistic state
      await PremiumService.initialize();

      expect(PremiumService.canChangePlanInApp, isFalse);
      final ok = await PremiumService.purchaseProduct(
        _product(PremiumService.yearlyProductId),
      );
      expect(ok, isFalse);
      expect(iap.bought, isEmpty);
    });

    test('buying the current plan again is refused', () async {
      await PremiumService.initialize();
      iap.controller.add([
        _purchase(PremiumService.monthlyProductId, PurchaseStatus.purchased),
      ]);
      await _settle();

      final ok = await PremiumService.purchaseProduct(
        _product(PremiumService.monthlyProductId),
      );
      expect(ok, isFalse);
      expect(iap.bought, isEmpty);
    });

    test('iOS switch uses a plain purchase param', () async {
      await PremiumService.initialize();
      iap.controller.add([
        _purchase(PremiumService.monthlyProductId, PurchaseStatus.purchased),
      ]);
      await _settle();

      await PremiumService.purchaseProduct(
        _product(PremiumService.yearlyProductId),
      );
      expect(iap.bought.single, isNot(isA<GooglePlayPurchaseParam>()));
    });
  });

  test('CachedEntitlement round-trips through JSON', () {
    final e = CachedEntitlement(productId: 'x', verifiedAt: now.toUtc());
    final parsed = CachedEntitlement.tryParse(
      '{"productId":"x","verifiedAt":"${now.toUtc().toIso8601String()}"}',
    );
    expect(parsed?.productId, e.productId);
    expect(parsed?.verifiedAt, e.verifiedAt);
    expect(CachedEntitlement.tryParse('garbage'), isNull);
  });
}
