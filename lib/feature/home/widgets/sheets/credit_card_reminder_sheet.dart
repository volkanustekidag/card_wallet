import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';
import 'package:wallet_app/core/utils/locale_format.dart';
import 'package:wallet_app/feature/card_detail/bank_card_page.dart';
import 'package:wallet_app/feature/card_detail/detail_chrome.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Opened from a reminder notification or the home notice: which card,
/// what's due and when, with the two things you usually want next —
/// copy the number, or open the card to change its reminders.
Future<void> showCreditCardReminderSheet(
  BuildContext context, {
  required CreditCard card,
  required CardReminderKind kind,
  DateTime? targetDate,
  int? daysUntil,
}) {
  final now = DateTime.now();
  final target = targetDate ?? _targetDateFor(card, kind, now);
  final days = daysUntil ??
      (target == null
          ? null
          : CardReminderRules.dateOnly(target)
              .difference(CardReminderRules.dateOnly(now))
              .inDays);

  return showCwSheet<void>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      final payment = kind == CardReminderKind.payment;
      final dateText = target == null
          ? 'reminderDateUnknown'.tr()
          : (payment ? 'paymentDueDateShort' : 'expiryDateShort').tr(
              namedArgs: {
                'date': LocaleFormat.yearMonthDay(sheet.locale).format(target),
              },
            );
      final daysText = days == null
          ? null
          : days <= 0
              ? 'dueToday'.tr()
              : 'daysLeft'.tr(namedArgs: {'days': '$days'});
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletCardFace(item: WalletItem.credit(card)),
              const SizedBox(height: 16),
              Row(
                children: [
                  CwIconTile(payment ? CwIcons.calendar : CwIcons.clock,
                      color: c.warn),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (payment
                                  ? 'paymentReminderSheetTitle'
                                  : 'expiryReminderSheetTitle')
                              .tr(),
                          style: CwType.headline.copyWith(color: c.ink),
                        ),
                        Text(dateText,
                            style: CwType.footnote.copyWith(color: c.mute)),
                      ],
                    ),
                  ),
                  if (daysText != null) CwPill.warn(sheet, daysText),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: CwButton.secondary(
                      'cwCopyNumber'.tr(),
                      icon: CwIcons.copy,
                      height: 50,
                      onPressed: () async {
                        await copySensitive(
                          sheet,
                          CardNumberLayout.digitsOf(card.creditCardNumber),
                          cardType: AnalyticsCardType.credit,
                        );
                        if (sheet.mounted) Navigator.pop(sheet);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CwButton(
                      'editReminderAction'.tr(),
                      icon: CwIcons.bell,
                      height: 50,
                      onPressed: () {
                        Navigator.pop(sheet);
                        Get.to<void>(() => BankCardPage(card: card));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

DateTime? _targetDateFor(
  CreditCard card,
  CardReminderKind kind,
  DateTime now,
) {
  switch (kind) {
    case CardReminderKind.expiry:
      return CardReminderRules.parseExpiryDate(card.expirationDate);
    case CardReminderKind.payment:
      final dueDay = CardReminderRules.safePaymentDueDay(card.paymentDueDay);
      if (dueDay == null) return null;
      return CardReminderRules.nextPaymentDate(now, dueDay);
  }
}
