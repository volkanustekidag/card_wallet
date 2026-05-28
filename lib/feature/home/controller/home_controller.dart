import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';

class HomeController extends GetxController {
  final CreditCardService _creditCardService = CreditCardService();
  final IbanCardService _ibanCardService = IbanCardService();
  final LoyaltyCardService _loyaltyCardService = LoyaltyCardService();

  var creditCards = <CreditCard>[].obs;
  var ibanCards = <IbanCard>[].obs;
  var loyaltyCards = <LoyaltyCard>[].obs;
  var isLoading = false.obs;
  final latestCreditCard = Rxn<CreditCard>();
  final latestIbanCard = Rxn<IbanCard>();
  final latestLoyaltyCard = Rxn<LoyaltyCard>();
  final upcomingExpiryNotices = <UpcomingCardDate>[].obs;
  final upcomingPaymentNotices = <UpcomingCardDate>[].obs;

  // Pre-merged + pre-sorted wallet timeline. Computed once per box change
  // (not per Obx tick) so the home page can read it without re-running an
  // O(n log n) sort on every scroll/carousel/filter rebuild.
  final walletItems = <WalletItem>[].obs;

  // Cache box-open futures so subsequent loadHomeContent() calls don't
  // re-run the open dance — Hive is happy to call openBox repeatedly but
  // it still costs a microtask on the UI thread per call.
  bool _boxesOpened = false;

  StreamSubscription<BoxEvent>? _ccSub;
  StreamSubscription<BoxEvent>? _ibanSub;
  StreamSubscription<BoxEvent>? _loyaltySub;
  Timer? _refreshDebounce;

  @override
  void onInit() {
    super.onInit();
    loadHomeContent().then((_) => _attachWatchers());
  }

  @override
  void onClose() {
    _ccSub?.cancel();
    _ibanSub?.cancel();
    _loyaltySub?.cancel();
    _refreshDebounce?.cancel();
    super.onClose();
  }

  /// Subscribe to every Hive box backing the wallet so the home page
  /// reflects any add / delete / update from anywhere — list pages,
  /// add/edit screens, the action sheet — without manual refreshes.
  /// A 100 ms debounce coalesces bursts (e.g. "delete N cards" loops).
  Future<void> _attachWatchers() async {
    try {
      final ccStream = await _creditCardService.watch();
      _ccSub = ccStream.listen((_) => _scheduleRefresh());
      final ibanStream = await _ibanCardService.watch();
      _ibanSub = ibanStream.listen((_) => _scheduleRefresh());
      final loyaltyStream = await _loyaltyCardService.watch();
      _loyaltySub = loyaltyStream.listen((_) => _scheduleRefresh());
    } catch (e) {
      debugPrint('HomeController: watcher setup failed: $e');
    }
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 100),
      loadHomeContent,
    );
  }

  Future<void> loadHomeContent() async {
    try {
      isLoading.value = true;
      if (!_boxesOpened) {
        await Future.wait([
          _creditCardService.openBox(),
          _ibanCardService.openBox(),
          _loyaltyCardService.openBox(),
        ]);
        _boxesOpened = true;
      }

      final results = await Future.wait([
        _creditCardService.getAllCreditCards(),
        _ibanCardService.getAllIbanCards(),
        _loyaltyCardService.getAllLoyaltyCards(),
      ]);
      final creditCardList = results[0] as List<CreditCard>;
      final ibanCardList = results[1] as List<IbanCard>;
      final loyaltyCardList = results[2] as List<LoyaltyCard>;

      creditCards.value = creditCardList;
      ibanCards.value = ibanCardList;
      loyaltyCards.value = loyaltyCardList;
      unawaited(
        AnalyticsService.instance.setCardCountTotal(
          creditCardList.length + ibanCardList.length + loyaltyCardList.length,
        ),
      );

      // Single sort here — every consumer reads walletItems instead of
      // calling mergeAndSort() in their build path.
      walletItems.value = mergeAndSort(
        credits: creditCardList,
        ibans: ibanCardList,
        loyalties: loyaltyCardList,
      );

      latestCreditCard.value = _findLatestCreditCard(creditCardList);
      latestIbanCard.value = _findLatestIbanCard(ibanCardList);
      latestLoyaltyCard.value = _findLatestLoyaltyCard(loyaltyCardList);
      upcomingExpiryNotices.value = CardReminderRules.upcomingExpiries(
        creditCardList,
        now: DateTime.now(),
      );
      upcomingPaymentNotices.value = CardReminderRules.upcomingPayments(
        creditCardList,
        now: DateTime.now(),
      );

      if (Get.isRegistered<PremiumController>()) {
        Get.find<PremiumController>().setCardCounts(
          creditCount: creditCardList.length,
          ibanCount: ibanCardList.length,
          loyaltyCount: loyaltyCardList.length,
        );
      }
    } catch (e) {
      debugPrint('Error loading home content: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void refreshData() {
    loadHomeContent();
  }

  CreditCard? _findLatestCreditCard(List<CreditCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }

  IbanCard? _findLatestIbanCard(List<IbanCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }

  LoyaltyCard? _findLatestLoyaltyCard(List<LoyaltyCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }
}
