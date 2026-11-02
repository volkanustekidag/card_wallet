import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/utils/share_origin.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/feature/card_detail/detail_chrome.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sheets/card_share_choice_sheet.dart';
import 'package:wallet_app/ui/navigation/card_hero.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_top_bar.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';
import 'package:wallet_app/core/utils/credit_card_label.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';

/// How long a revealed card number stays on screen.
const int kRevealSeconds = 30;

/// Bank card detail: the card, a timed number reveal, one-tap copies and
/// the card's reminders as inline switches.
class BankCardPage extends StatefulWidget {
  final CreditCard card;

  const BankCardPage({super.key, required this.card});

  @override
  State<BankCardPage> createState() => _BankCardPageState();
}

class _BankCardPageState extends State<BankCardPage> {
  /// Re-read after an edit: saving stores a new object under the card's id.
  late CreditCard _card = widget.card;
  CreditCard get card => _card;

  Timer? _ticker;
  int _secondsLeft = 0;
  bool _biometric = false;

  bool get _revealed => _secondsLeft > 0;

  @override
  void initState() {
    super.initState();
    BiometricService().isBiometricEnabled().then((v) {
      if (mounted) setState(() => _biometric = v);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _toggleReveal() async {
    if (_revealed) {
      _hide();
      return;
    }
    // With biometric unlock on, the number needs the same proof again;
    // without it the app's PIN lock already guards this screen.
    if (_biometric) {
      bool ok = false;
      try {
        ok = await BiometricService().authenticateWithBiometric(
          localizedReason: 'cwRevealReason'.tr(),
        );
      } catch (_) {
        ok = false;
      }
      if (!ok || !mounted) return;
    }
    HapticFeedback.lightImpact();
    setState(() => _secondsLeft = kRevealSeconds);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  void _hide() {
    _ticker?.cancel();
    setState(() => _secondsLeft = 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final item = WalletItem.credit(card);
    final notes = card.notes?.trim() ?? '';
    return CwPageStyle(
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: CwScrollEdge(
            bar: DetailTopBar(title: titleForItem(item), onMore: _openMore),
            body: ListView(
              padding: EdgeInsets.fromLTRB(
                CwSpace.gutter,
                8,
                CwSpace.gutter,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Hero(
                  tag: item.heroTag,
                  flightShuttleBuilder: cardHeroShuttle,
                  child: WalletCardFace(
                    item: item,
                    interactive: true,
                    revealNumber: _revealed,
                  ),
                ),
                const SizedBox(height: 14),
                CwGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    CwRow(
                      leading: CwIcon(
                        _revealed
                            ? CwIcons.eyeOff
                            : (_biometric ? CwIcons.faceId : CwIcons.eye),
                        color: c.ink,
                      ),
                      title: _revealed
                          ? 'cwHideNumber'.tr()
                          : (_biometric
                              ? 'cwRevealBiometric'.tr()
                              : 'cwRevealNumber'.tr()),
                      value: _revealed
                          ? 'cwHidesIn'.tr(args: ['$_secondsLeft'])
                          : null,
                      onTap: _toggleReveal,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionTile(
                        icon: CwIcons.copy,
                        label: 'cwCopyNumber'.tr(),
                        onTap: () => copySensitive(
                          context,
                          CardNumberLayout.digitsOf(card.creditCardNumber),
                          cardType: AnalyticsCardType.credit,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: QuickActionTile(
                        icon: CwIcons.calendar,
                        label: 'cwCopyExpiry'.tr(),
                        onTap: () => copySensitive(
                          context,
                          card.expirationDate.replaceAll(' ', ''),
                          cardType: AnalyticsCardType.credit,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: QuickActionTile(
                        icon: CwIcons.share,
                        label: 'cwShare'.tr(),
                        onTap: _share,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: QuickActionTile(
                        icon: CwIcons.edit,
                        label: 'cwEdit'.tr(),
                        onTap: _edit,
                      ),
                    ),
                  ],
                ),
                CwSectionHeader(
                  'cwReminders'.tr(),
                  padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
                ),
                _Reminders(card: card, onChanged: () => setState(() {})),
                if (notes.isNotEmpty) ...[
                  CwSectionHeader(
                    'cwNotes'.tr(),
                    padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(CwRadius.m),
                    ),
                    child: SelectableText(
                      notes,
                      style: CwType.body.copyWith(color: c.ink),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                CwTrustLine('cwEncryptedLocal'.tr()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sharing a full PAN + name + expiry is enough to use the card online,
  /// so ask first: masked (last 4 only) is the default, full number comes
  /// with a warning.
  Future<void> _share() async {
    final digits = CardNumberLayout.digitsOf(card.creditCardNumber);
    final last4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    final choice = await showCardShareChoiceSheet(context, last4: last4);
    if (choice == null || !mounted) return;
    AnalyticsService.instance.logCardShared(
      cardType: AnalyticsCardType.credit,
      masked: choice == CardShareChoice.masked,
    );
    final text = choice == CardShareChoice.masked
        ? [creditCardLabel(card), '•••• $last4', card.cardHolder]
            .where((part) => part.trim().isNotEmpty)
            .join(' • ')
        : '${creditCardLabel(card)} • ${CardNumberLayout.format(card.creditCardNumber)}'
            ' • ${card.cardHolder} • ${card.expirationDate}';
    await shareText(text, origin: shareOriginFromContext(context));
  }

  /// Edits on top of this page and comes back to it, updated.
  Future<void> _edit() async {
    await Get.to<void>(
      () => AddCreditCardPage(creditCard: card),
      binding: AddCreditCardBindings(),
    );
    final cards = await CreditCardService().getAllCreditCards();
    final fresh = cards.where((c) => c.id == card.id).firstOrNull;
    if (fresh != null && mounted) setState(() => _card = fresh);
  }

  Future<void> _openMore() async {
    final c = CwColors.of(context);
    final fav = isFavoriteCard(card);
    await showCwSheet<void>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: CwGroup(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            CwRow(
              leading: CwIcon(fav ? CwIcons.starFill : CwIcons.star,
                  color: fav ? c.warn : c.ink),
              title: fav ? 'cwFavRemove'.tr() : 'cwFavAdd'.tr(),
              onTap: () {
                Navigator.pop(sheet);
                HapticFeedback.lightImpact();
                toggleFavoriteTag(card);
                if (mounted) setState(() {});
              },
            ),
            CwRow(
              leading: CwIcon(CwIcons.trash, color: c.danger),
              title: 'cwDelete'.tr(),
              titleColor: c.danger,
              onTap: () {
                Navigator.pop(sheet);
                _delete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showConfirmActionSheet(
      context: context,
      title: 'deleteCreditCard'.tr(),
      content: 'deleteDataMessage'.tr(),
    );
    if (!ok) return;
    await Get.find<CreditCardController>().removeCreditCard(card);
    if (mounted) Navigator.of(context).pop();
  }
}

/// Payment + expiry reminders. Each switch saves the card and reschedules
/// its notifications right away; turning the payment one on without a due
/// day asks for the day first.
class _Reminders extends StatelessWidget {
  final CreditCard card;
  final VoidCallback onChanged;

  const _Reminders({required this.card, required this.onChanged});

  Future<void> _apply(BuildContext context) async {
    await card.save();
    onChanged();
    await CardReminderService.guarded(
      'bankCard.reminders',
      () => CardReminderService().scheduleForCard(card),
    );
    if (!card.paymentReminderEnabled && !card.expiryReminderEnabled) return;
    final allowed = await CardReminderService()
        .notificationsEnabled()
        .catchError((_) => true);
    if (!allowed && context.mounted) {
      context.showWarningSnackBar('cwNotifOff');
    }
  }

  Future<void> _togglePayment(BuildContext context, bool on) async {
    if (on && card.paymentDueDay == null) {
      final day = await pickDueDay(context, initial: null);
      if (day == null) return;
      card.paymentDueDay = day;
    }
    card.paymentReminderEnabled = on;
    if (context.mounted) await _apply(context);
  }

  Future<void> _changeDay(BuildContext context) async {
    final day = await pickDueDay(context, initial: card.paymentDueDay);
    if (day == null) return;
    card.paymentDueDay = day;
    card.paymentReminderEnabled = true;
    if (context.mounted) await _apply(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final day = card.paymentDueDay;
    final expiry = card.expirationDate.replaceAll(' ', '');
    return CwGroup(
      margin: EdgeInsets.zero,
      children: [
        CwRow(
          title: day == null
              ? 'cwPaymentDue'.tr()
              : 'cwPaymentDueOn'.tr(args: ['$day']),
          subtitle: day == null
              ? 'cwPaymentDueSet'.tr()
              : 'cwRemindDaysBefore'.plural(card.paymentReminderDaysBefore),
          subtitleColor: c.mute,
          onTap: () => _changeDay(context),
          trailing: CwSwitch(
            value: card.paymentReminderEnabled && day != null,
            onChanged: (v) => _togglePayment(context, v),
          ),
        ),
        if (expiry.isNotEmpty)
          CwRow(
            title: 'cwCardExpiresOn'.tr(args: [expiry]),
            subtitle:
                'cwRemindDaysBefore'.plural(card.expiryReminderDaysBefore),
            subtitleColor: c.mute,
            trailing: CwSwitch(
              value: card.expiryReminderEnabled,
              onChanged: (v) {
                card.expiryReminderEnabled = v;
                _apply(context);
              },
            ),
          ),
      ],
    );
  }
}

/// Grid of days 1–31 in a sheet. Returns the picked day or null.
Future<int?> pickDueDay(BuildContext context, {int? initial}) {
  return showCwSheet<int>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('cwPickDueDay'.tr(),
                  style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (var d = 1; d <= 31; d++)
                    Material(
                      color: d == initial ? c.ink : c.surface2,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(sheet, d),
                        child: Center(
                          child: Text(
                            '$d',
                            style: CwType.mono(
                              size: 15,
                              color: d == initial ? c.bg : c.ink,
                            ),
                          ),
                        ),
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
