import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card_page.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/import/import_page.dart';
import 'package:wallet_app/feature/scanner/live_scanner_page.dart';
import 'package:wallet_app/feature/scanner/loyalty_confirm_sheet.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// The one "+" of the app: opens the live scanner.
Future<void> openScanner({ScanMode mode = ScanMode.auto}) async {
  await Get.to<void>(
    () => LiveScannerPage(initialMode: mode),
    fullscreenDialog: true,
    transition: Transition.downToUp,
  );
}

/// Routes a confirmed scan. Loyalty: confirm sheet over the scanner (the
/// scanner closes once saved). Bank card / IBAN: the prefilled form
/// replaces the scanner. True when the scanner is done.
Future<bool> handleScanHit(BuildContext context, ScanHit hit) async {
  switch (hit) {
    case LoyaltyHit():
      final saved = await showLoyaltyConfirmSheet(
        context,
        raw: hit.raw,
        format: hit.format,
        brand: hit.brand,
      );
      if (saved && context.mounted) Navigator.of(context).maybePop();
      return saved;
    case CardHit():
      Get.off<void>(
        () => AddCreditCardPage(prefill: hit),
        binding: AddCreditCardBindings(),
      );
      return true;
    case IbanHit():
      Get.off<void>(
        () => AddIbanCardPage(prefill: hit),
        binding: AddIbanCardBindings(),
      );
      return true;
  }
}

/// "1 of 3 free" under a card type on the free plan, so the limit is never
/// a surprise; null on Premium or when the counts aren't known.
String? freeSlotsLine(CardLimitType type) {
  if (!Get.isRegistered<PremiumController>() ||
      !Get.isRegistered<HomeController>()) {
    return null;
  }
  final premium = Get.find<PremiumController>();
  if (premium.isPremium) return null;
  final home = Get.find<HomeController>();
  final used = switch (type) {
    CardLimitType.loyalty => home.loyaltyCards.length,
    CardLimitType.credit => home.creditCards.length,
    CardLimitType.iban => home.ibanCards.length,
  };
  final limit = premium.freeLimitFor(type);
  return used >= limit
      ? 'cwFreeFull'.tr()
      : 'cwFreeCount'.tr(args: ['$used', '$limit']);
}

/// "Type it in": choose what to add, then the manual form (limit gate in
/// [goToAddCard]). With [replace] the caller (scanner) closes first.
/// [type] skips the question when the scanner already knows what's being
/// added (a mode other than auto).
Future<void> pickManualEntry(BuildContext context,
    {bool replace = false, CardLimitType? type}) async {
  type ??= await showCwSheet<CardLimitType>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 6),
              child: Text('cwWhatAdding'.tr(),
                  style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
            ),
            CwGroup(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              children: [
                CwRow(
                  leading: CwIconTile(CwIcons.barcode, color: c.ok),
                  title: 'cwLoyaltyCard'.tr(),
                  subtitle: freeSlotsLine(CardLimitType.loyalty),
                  chevron: true,
                  onTap: () => Navigator.pop(sheet, CardLimitType.loyalty),
                ),
                CwRow(
                  leading: CwIconTile(CwIcons.card, color: c.ink),
                  title: 'cwBankCard'.tr(),
                  subtitle: freeSlotsLine(CardLimitType.credit),
                  chevron: true,
                  onTap: () => Navigator.pop(sheet, CardLimitType.credit),
                ),
                CwRow(
                  leading:
                      CwIconTile(CwIcons.bank, color: const Color(0xFF2E6385)),
                  title: 'cwIbanAccount'.tr(),
                  subtitle: freeSlotsLine(CardLimitType.iban),
                  chevron: true,
                  onTap: () => Navigator.pop(sheet, CardLimitType.iban),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  final chosen = type;
  if (chosen == null) return;
  if (replace && context.mounted) Navigator.of(context).pop();
  final ctx = Get.context;
  if (ctx == null || !ctx.mounted) return;
  await goToAddCard(context: ctx, type: chosen);
}

/// Import from other wallet apps / files.
Future<void> openImport(BuildContext context, {bool replace = false}) async {
  if (replace) {
    await Get.off<void>(() => const ImportPage());
  } else {
    await Get.to<void>(() => const ImportPage());
  }
}
