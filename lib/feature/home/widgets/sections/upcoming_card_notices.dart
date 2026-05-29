import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/styles/app_themes.dart';
import 'package:wallet_app/core/styles/shadows.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';
import 'package:wallet_app/core/widgets/lifted_surface.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sheets/credit_card_reminder_sheet.dart';

enum _NoticeKind { payment, expiry }

enum _Severity { critical, warning, info }

class _SeverityPalette {
  final _Severity level;
  final Color tint;
  final Color border;
  final Color foreground;
  final Color stripe;

  const _SeverityPalette({
    required this.level,
    required this.tint,
    required this.border,
    required this.foreground,
    required this.stripe,
  });
}

_SeverityPalette _severityFor(
  BuildContext context,
  int daysUntil,
  _NoticeKind kind,
) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final warn = isDark ? AppThemes.darkWarning : AppThemes.lightWarning;

  if (daysUntil <= 0) {
    return _SeverityPalette(
      level: _Severity.critical,
      tint: cs.error.withValues(alpha: isDark ? 0.16 : 0.10),
      border: cs.error.withValues(alpha: 0.40),
      foreground: cs.error,
      stripe: cs.error,
    );
  }

  final warnThreshold = kind == _NoticeKind.payment ? 3 : 14;
  if (daysUntil <= warnThreshold) {
    return _SeverityPalette(
      level: _Severity.warning,
      tint: warn.withValues(alpha: isDark ? 0.14 : 0.10),
      border: warn.withValues(alpha: 0.35),
      foreground: warn,
      stripe: warn,
    );
  }

  final base = kind == _NoticeKind.payment ? cs.primary : cs.tertiary;
  return _SeverityPalette(
    level: _Severity.info,
    tint: base.withValues(alpha: 0.06),
    border: base.withValues(alpha: 0.20),
    foreground: base,
    stripe: base.withValues(alpha: 0.55),
  );
}

class UpcomingCardNotices extends StatelessWidget {
  final HomeController controller;

  const UpcomingCardNotices({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.upcomingPaymentNotices.toList();
      final expiries = controller.upcomingExpiryNotices.toList();
      if (payments.isEmpty && expiries.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          kSpaceLg,
          kSpaceSm,
          kSpaceLg,
          kSpaceSm,
        ),
        child: Column(
          children: [
            if (payments.isNotEmpty)
              _NoticePanel(
                title: 'upcomingPaymentsTitle'.tr(),
                icon: Icons.payments_outlined,
                kind: _NoticeKind.payment,
                notices: payments,
                subtitleBuilder: (notice) => 'paymentDueDateShort'.tr(
                  namedArgs: {
                    'date': DateFormat.MMMd().format(notice.targetDate),
                  },
                ),
              ),
            if (payments.isNotEmpty && expiries.isNotEmpty)
              const SizedBox(height: kSpaceMd),
            if (expiries.isNotEmpty)
              _NoticePanel(
                title: 'upcomingExpiriesTitle'.tr(),
                icon: Icons.credit_card_off_outlined,
                kind: _NoticeKind.expiry,
                notices: expiries,
                subtitleBuilder: (notice) => 'expiryDateShort'.tr(
                  namedArgs: {
                    'date': DateFormat.MMMd().format(notice.targetDate),
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _NoticePanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final _NoticeKind kind;
  final List<UpcomingCardDate> notices;
  final String Function(UpcomingCardDate notice) subtitleBuilder;

  const _NoticePanel({
    required this.title,
    required this.icon,
    required this.kind,
    required this.notices,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = notices.take(3).toList();

    final urgentCount = notices.where((n) => n.daysUntil <= 0).length;
    final warnThreshold = kind == _NoticeKind.payment ? 3 : 14;
    final warnCount = notices
        .where((n) => n.daysUntil > 0 && n.daysUntil <= warnThreshold)
        .length;

    final headerSeverity = _severityFor(
      context,
      urgentCount > 0
          ? 0
          : warnCount > 0
              ? 1
              : 999,
      kind,
    );

    return LiftedSurface(
      border: Border.all(color: headerSeverity.border),
      boxShadow: headerSeverity.level == _Severity.critical
          ? [
              BoxShadow(
                color: headerSeverity.foreground.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ]
          : Shadows.shadowLifted,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: headerSeverity.tint,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: headerSeverity.foreground.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: headerSeverity.foreground,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (urgentCount > 0) ...[
                  _SummaryPill(
                    count: urgentCount,
                    color: colorScheme.error,
                    showPulse: true,
                    label: kind == _NoticeKind.payment
                        ? 'noticeDueNowSummary'
                            .tr(namedArgs: {'count': urgentCount.toString()})
                        : 'noticeExpiringNowSummary'
                            .tr(namedArgs: {'count': urgentCount.toString()}),
                  ),
                  const SizedBox(width: 6),
                ] else if (warnCount > 0) ...[
                  _SummaryPill(
                    count: warnCount,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppThemes.darkWarning
                        : AppThemes.lightWarning,
                    showPulse: false,
                    label: 'noticeSoonSummary'
                        .tr(namedArgs: {'count': warnCount.toString()}),
                  ),
                  const SizedBox(width: 6),
                ],
                if (notices.length > visible.length)
                  Text(
                    '+${notices.length - visible.length}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < visible.length; i++) ...[
            _NoticeRow(
              notice: visible[i],
              kind: kind,
              subtitle: subtitleBuilder(visible[i]),
            ),
            if (i < visible.length - 1)
              Divider(
                height: 1,
                indent: 22,
                endIndent: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final int count;
  final Color color;
  final bool showPulse;
  final String label;

  const _SummaryPill({
    required this.count,
    required this.color,
    required this.showPulse,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPulse) ...[
            _PulseDot(color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          final ringSize = 4 + 8 * t;
          final ringOpacity = (1 - t).clamp(0.0, 1.0) * 0.55;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: ringOpacity),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final UpcomingCardDate notice;
  final _NoticeKind kind;
  final String subtitle;

  const _NoticeRow({
    required this.notice,
    required this.kind,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = notice.card;
    final severity = _severityFor(context, notice.daysUntil, kind);
    final isCritical = severity.level == _Severity.critical;
    final isWarning = severity.level == _Severity.warning;

    return Material(
      color: isCritical || isWarning ? severity.tint : Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => showCreditCardReminderSheet(
          context,
          card: card,
          kind: kind == _NoticeKind.payment
              ? CardReminderKind.payment
              : CardReminderKind.expiry,
          targetDate: notice.targetDate,
          daysUntil: notice.daysUntil,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 12, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: severity.stripe,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
              _MiniCardBadge(card: card, accent: severity.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cardTitle(card),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _DaysChip(daysUntil: notice.daysUntil, severity: severity),
            ],
          ),
        ),
      ),
    );
  }

  String _cardTitle(CreditCard card) {
    final bankName = card.bankName.trim();
    if (bankName.isNotEmpty) return bankName;
    return 'creditCard'.tr();
  }
}

class _MiniCardBadge extends StatelessWidget {
  final CreditCard card;
  final Color accent;

  const _MiniCardBadge({
    required this.card,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      alignment: Alignment.center,
      child: Text(
        _lastFour(card),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  String _lastFour(CreditCard card) {
    final digits = card.creditCardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '••••';
    return digits.substring(digits.length - 4);
  }
}

class _DaysChip extends StatelessWidget {
  final int daysUntil;
  final _SeverityPalette severity;

  const _DaysChip({
    required this.daysUntil,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final text = daysUntil <= 0
        ? 'dueToday'.tr()
        : 'daysLeft'.tr(namedArgs: {'days': daysUntil.toString()});
    final isCritical = severity.level == _Severity.critical;
    final isWarning = severity.level == _Severity.warning;
    final showIcon = isCritical || isWarning;
    final iconData = isCritical
        ? Icons.notifications_active_rounded
        : Icons.schedule_rounded;

    return Container(
      constraints: const BoxConstraints(minWidth: 58),
      padding: EdgeInsets.fromLTRB(showIcon ? 7 : 10, 5, 10, 5),
      decoration: BoxDecoration(
        color: severity.foreground.withValues(alpha: isCritical ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: severity.foreground
              .withValues(alpha: isCritical ? 0.45 : (isWarning ? 0.30 : 0.0)),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(iconData, size: 12, color: severity.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: severity.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
