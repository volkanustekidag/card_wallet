import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/body.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sheets/credit_card_reminder_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _homeController;
  StreamSubscription<CardReminderPayload>? _reminderTapSub;
  DateTime? _lastBackPressTime;
  bool _isReminderSheetOpen = false;
  bool _initialAddSheetHandled = false;

  @override
  void initState() {
    super.initState();
    _homeController = Get.find<HomeController>();
    _reminderTapSub = CardReminderService().reminderPayloads.listen(
          _openReminderPayload,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = CardReminderService().takePendingPayload();
      if (payload != null) {
        _openReminderPayload(payload);
      }
      _maybeShowRecoveryPinResetPrompt();
      unawaited(_maybeOpenInitialAddSheet());
    });
  }

  Future<void> _maybeOpenInitialAddSheet() async {
    if (_initialAddSheetHandled || !mounted) return;
    final args = Get.arguments;
    if (args is! Map || args['open_add_card_sheet'] != true) return;
    _initialAddSheetHandled = true;
    if (_homeController.isLoading.value) {
      await _homeController.loadHomeContent();
    }
    if (!mounted) return;
    // Short breathing room so the user perceives the home screen — but
    // not so long that the transition feels stuck. The loading spinner
    // already eats a few hundred ms on cold launch; piling another full
    // second on top reads as "frozen". 600ms after content lands is
    // enough to glimpse the welcome stack before the picker covers it.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await showAddCardTypeSheet(context);
  }

  void _maybeShowRecoveryPinResetPrompt() {
    if (!mounted) return;
    if (!Get.isRegistered<AuthController>()) return;
    final auth = Get.find<AuthController>();
    if (!auth.consumeRecoveryPrompt()) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('resetPinPrompt'.tr()),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'resetPinNow'.tr(),
            onPressed: () => Get.to<bool>(
              () => const PinActionPage(),
              arguments: PinAction.create,
            ),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _reminderTapSub?.cancel();
    super.dispose();
  }

  void _handlePopInvoked(bool didPop) {
    if (didPop) return;
    final now = DateTime.now();
    final last = _lastBackPressTime;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('pressBackAgainToExit'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }
    SystemNavigator.pop();
  }

  Future<void> _openReminderPayload(CardReminderPayload payload) async {
    if (!mounted || _isReminderSheetOpen) return;
    CardReminderService().takePendingPayload();

    if (_homeController.isLoading.value) {
      await _homeController.loadHomeContent();
    }

    var card = _findCreditCard(payload.cardId);
    if (card == null) {
      await _homeController.loadHomeContent();
      card = _findCreditCard(payload.cardId);
    }
    if (card == null || !mounted) return;

    _isReminderSheetOpen = true;
    try {
      await showCreditCardReminderSheet(
        context,
        card: card,
        kind: payload.kind,
      );
    } finally {
      _isReminderSheetOpen = false;
    }
  }

  CreditCard? _findCreditCard(String id) {
    for (final card in _homeController.creditCards) {
      if (card.id.toString() == id) {
        return card;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePopInvoked(didPop),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Obx(() {
          if (_homeController.isLoading.value) {
            return const LoadingWidget();
          }
          return HomeBody(controller: _homeController);
        }),
      ),
    );
  }
}
