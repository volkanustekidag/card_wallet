import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

Future<void> showCreditCardReminderSheet(
  BuildContext context, {
  required CreditCard card,
  required CardReminderKind kind,
  DateTime? targetDate,
  int? daysUntil,
}) {
  final now = DateTime.now();
  final resolvedTargetDate = targetDate ?? _targetDateFor(card, kind, now);
  final resolvedDaysUntil = daysUntil ??
      (resolvedTargetDate == null
          ? null
          : CardReminderRules.dateOnly(resolvedTargetDate)
              .difference(CardReminderRules.dateOnly(now))
              .inDays);

  return showGeneralDialog<void>(
    context: context,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: kMediumAnim,
    pageBuilder: (_, __, ___) => _CreditCardReminderSheet(
      card: card,
      kind: kind,
      targetDate: resolvedTargetDate,
      daysUntil: resolvedDaysUntil,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: kHomeCurve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
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

class _CreditCardReminderSheet extends StatelessWidget {
  final CreditCard card;
  final CardReminderKind kind;
  final DateTime? targetDate;
  final int? daysUntil;

  const _CreditCardReminderSheet({
    required this.card,
    required this.kind,
    required this.targetDate,
    required this.daysUntil,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width * 0.82).clamp(280.0, 380.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: kSpaceLg,
        vertical: kSpaceXL,
      ),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kSpaceLg,
          kSpaceMd,
          kSpaceLg,
          kSpaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHandle(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: kSpaceMd),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: cardWidth,
                child: AspectRatio(
                  aspectRatio: 1.586,
                  child: CreditCardFront(creditCard: card),
                ),
              ),
            ),
            const SizedBox(height: kSpaceLg),
            _ReminderHeader(
              kind: kind,
              targetDate: targetDate,
              daysUntil: daysUntil,
            ),
            const SizedBox(height: kSpaceMd),
            _InfoGrid(card: card, kind: kind),
            const SizedBox(height: kSpaceLg),
            Row(
              children: [
                Expanded(
                  child: _SheetAction(
                    icon: Icons.copy_rounded,
                    label: 'actCopy'.tr(),
                    onTap: () => _copyCardNumber(context),
                  ),
                ),
                const SizedBox(width: kSpaceSm),
                Expanded(
                  child: _SheetAction(
                    icon: Icons.tune_rounded,
                    label: 'editReminderAction'.tr(),
                    onTap: () => _editCard(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyCardNumber(BuildContext context) async {
    HapticFeedback.lightImpact();
    await SensitiveClipboard.copy(card.creditCardNumber);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _editCard(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    Get.to(
      () => AddCreditCardPage(creditCard: card),
      binding: AddCreditCardBindings(),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final VoidCallback onClose;

  const _SheetHandle({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderHeader extends StatelessWidget {
  final CardReminderKind kind;
  final DateTime? targetDate;
  final int? daysUntil;

  const _ReminderHeader({
    required this.kind,
    required this.targetDate,
    required this.daysUntil,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = kind == CardReminderKind.payment
        ? colorScheme.primary
        : colorScheme.tertiary;
    final title = kind == CardReminderKind.payment
        ? 'paymentReminderSheetTitle'.tr()
        : 'expiryReminderSheetTitle'.tr();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            kind == CardReminderKind.payment
                ? Icons.payments_outlined
                : Icons.event_available_outlined,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DaysPill(daysUntil: daysUntil, accent: accent),
        ],
      ),
    );
  }

  String _dateText() {
    if (targetDate == null) return 'reminderDateUnknown'.tr();
    final key = kind == CardReminderKind.payment
        ? 'paymentDueDateShort'
        : 'expiryDateShort';
    return key.tr(
      namedArgs: {'date': DateFormat.yMMMd().format(targetDate!)},
    );
  }
}

class _DaysPill extends StatelessWidget {
  final int? daysUntil;
  final Color accent;

  const _DaysPill({
    required this.daysUntil,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final days = daysUntil;
    final text = days == null
        ? '—'
        : days == 0
            ? 'dueToday'.tr()
            : 'daysLeft'.tr(namedArgs: {'days': days.toString()});

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final CreditCard card;
  final CardReminderKind kind;

  const _InfoGrid({
    required this.card,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoRowData(
          'bName'.tr(),
          card.bankName.trim().isEmpty
              ? 'unknownBank'.tr()
              : card.bankName.trim()),
      _InfoRowData('cardholderLabel'.tr(), card.cardHolder),
      _InfoRowData('expiryLabel'.tr(), card.expirationDate),
      if (card.paymentDueDay != null)
        _InfoRowData('paymentDueDayLabel'.tr(), card.paymentDueDay.toString()),
      _InfoRowData(
        'notificationStatusLabel'.tr(),
        _notificationStatusText(),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _InfoRow(row: rows[i]),
          if (i < rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _notificationStatusText() {
    final enabled = kind == CardReminderKind.payment
        ? card.paymentReminderEnabled
        : card.expiryReminderEnabled;
    return enabled ? 'enabled'.tr() : 'disabled'.tr();
  }
}

class _InfoRowData {
  final String label;
  final String value;

  const _InfoRowData(this.label, this.value);
}

class _InfoRow extends StatelessWidget {
  final _InfoRowData row;

  const _InfoRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            row.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: colorScheme.onSurface.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
