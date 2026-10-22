import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/widgets/notes_and_tags_section.dart';
import 'package:wallet_app/core/widgets/notification_permission_banner.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_number_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_valid_thru_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/utils/upper_case_formatter.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/scanner/live_scanner_page.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/ui/card/material_picker.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/components/cw_form.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';

/// Add / edit a bank card. The card on top updates live as you type; the
/// bank is filled in from the BIN; reminders, material and notes sit below.
/// [prefill] comes from the live scanner.
class AddCreditCardPage extends StatefulWidget {
  final CreditCard? creditCard;
  final CardHit? prefill;

  const AddCreditCardPage({Key? key, this.creditCard, this.prefill})
      : super(key: key);

  @override
  State<AddCreditCardPage> createState() => _AddCreditCardPageState();
}

class _AddCreditCardPageState extends State<AddCreditCardPage> {
  late final AddCreditCardController _c = Get.find<AddCreditCardController>();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _dueDay = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.creditCard != null) {
      _c.initializeForEdit(widget.creditCard!);
    } else {
      _c.initializeForCreate();
    }
    final card = _c.currentCard.value;
    _number.text = card.creditCardNumber;
    _expiry.text = card.expirationDate;
    _holder.text = card.cardHolder;
    _bank.text = card.bankName;
    _dueDay.text = card.paymentDueDay?.toString() ?? '';
    final p = widget.prefill;
    if (p != null) _apply(p);
  }

  @override
  void dispose() {
    for (final t in [_number, _expiry, _holder, _bank, _dueDay]) {
      t.dispose();
    }
    super.dispose();
  }

  void _apply(CardHit hit) {
    _number.text = CardNumberLayout.format(hit.number);
    _onNumber(_number.text);
    if (hit.expiry != null) {
      _expiry.text = hit.expiry!;
      _c.updateCardField('expirationDate', hit.expiry!);
    }
    if (hit.holder != null) {
      _holder.text = hit.holder!.toUpperCase();
      _c.updateCardField('cardHolder', _holder.text);
    }
  }

  void _onNumber(String v) {
    _c.updateCardField('creditCardNumber', v);
    // The number is the source of truth for the bank; the field stays
    // editable but typing the number again re-fills it.
    final detected = CardBankDetector.detect(v);
    if (detected != null && _bank.text != detected) {
      _bank.text = detected;
      _c.updateCardField('bankName', detected);
    }
  }

  void _onDueDay(String v) {
    final parsed = int.tryParse(v);
    if (parsed == null) {
      _c.updateCardField('paymentDueDay', null);
      return;
    }
    final day = parsed.clamp(1, 31).toInt();
    if (day != parsed) {
      _dueDay.value = TextEditingValue(
        text: '$day',
        selection: TextSelection.collapsed(offset: '$day'.length),
      );
    }
    _c.updateCardField('paymentDueDay', day);
  }

  Future<void> _scan() async {
    final hit = await Navigator.of(context).push<ScanHit>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const LiveScannerPage(
        initialMode: ScanMode.card,
        returnHit: true,
      ),
    ));
    if (hit is CardHit && mounted) setState(() => _apply(hit));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final card = _c.currentCard.value;
      final editing = _c.isEditMode.value;
      final network = CardBankDetector.networkFor(card.creditCardNumber);
      return CwFormScaffold(
        title: editing ? 'cwEditCard'.tr() : 'cwNewBankCard'.tr(),
        action: editing
            ? null
            : CwHeaderAction(
                icon: CwIcons.scan, label: 'cwScan'.tr(), onTap: _scan),
        preview: WalletCardFace(
          item: WalletItem.credit(card),
          revealNumber: true,
        ),
        button: CwButton(
          editing ? 'cwSave'.tr() : 'cwAddCard'.tr(),
          loading: _c.isLoading.value,
          onPressed: _c.isFormValid && !_c.isLoading.value
              ? () => _c.saveCard()
              : null,
        ),
        children: [
          CwField(
            controller: _number,
            label: 'cwCardNumber'.tr(),
            hint: '0000 0000 0000 0000',
            mono: true,
            autofocus: !editing && widget.prefill == null,
            keyboardType: TextInputType.number,
            maxLength: 23,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CardNumberFormatter(),
            ],
            onChanged: _onNumber,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: CwField(
                  controller: _expiry,
                  label: 'cwExpiresField'.tr(),
                  hint: 'MM / YY',
                  mono: true,
                  keyboardType: TextInputType.number,
                  maxLength: 7,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s/]')),
                    CardValidThruFormatter(),
                  ],
                  onChanged: (v) => _c.updateCardField('expirationDate', v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: CwField(
                  controller: _holder,
                  label: 'cwNameOnCard'.tr(),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 26,
                  inputFormatters: [UpperCaseTextFormatter()],
                  autofillHints: const [AutofillHints.creditCardName],
                  onChanged: (v) =>
                      _c.updateCardField('cardHolder', v.toUpperCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CwField(
            controller: _bank,
            label: 'cwBank'.tr(),
            hint: 'unknownBank'.tr(),
            maxLength: 32,
            onChanged: (v) => _c.updateCardField('bankName', v),
          ),
          const SizedBox(height: 10),
          network == CardNetwork.unknown
              ? CwTrustLine('cwCvcNever'.tr(), icon: CwIcons.shield)
              : CwNotice.ok(
                  context, 'cwNetworkDetected'.tr(args: [network.label])),
          const SizedBox(height: 18),
          MaterialPicker(
            selected: card.cardColorId,
            onSelected: (i) => _c.updateCardField('cardColorId', i),
          ),
          CwSectionHeader('cwReminders'.tr(),
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 8)),
          const NotificationPermissionBanner(
              margin: EdgeInsets.only(bottom: 10)),
          CwGroup(
            margin: EdgeInsets.zero,
            children: [
              CwRow(
                title: 'cwExpiryReminder'.tr(),
                trailing: CwSwitch(
                  value: card.expiryReminderEnabled,
                  onChanged: (v) =>
                      _c.updateCardField('expiryReminderEnabled', v),
                ),
              ),
              if (card.expiryReminderEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: CwChoiceChips<int>(
                    values: const [7, 14, 30, 60],
                    selected: card.expiryReminderDaysBefore,
                    label: (d) => 'cwDaysShort'.plural(d),
                    onSelected: (d) =>
                        _c.updateCardField('expiryReminderDaysBefore', d),
                  ),
                ),
              CwRow(
                title: 'cwPaymentReminder'.tr(),
                trailing: CwSwitch(
                  value: card.paymentReminderEnabled,
                  onChanged: (v) {
                    if (v && card.paymentDueDay == null) {
                      _dueDay.text = '15';
                      _c.updateCardField('paymentDueDay', 15);
                    }
                    _c.updateCardField('paymentReminderEnabled', v);
                  },
                ),
              ),
              if (card.paymentReminderEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CwField(
                        controller: _dueDay,
                        label: 'cwPaymentDayField'.tr(),
                        hint: '15',
                        mono: true,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: _onDueDay,
                      ),
                      const SizedBox(height: 10),
                      CwChoiceChips<int>(
                        values: const [0, 1, 3, 7],
                        selected: card.paymentReminderDaysBefore,
                        label: (d) =>
                            d == 0 ? 'cwSameDay'.tr() : 'cwDaysShort'.plural(d),
                        onSelected: (d) => _c.updateCardField(
                            'paymentReminderDaysBefore', d),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          CwSectionHeader('cwNotesTags'.tr(),
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 8)),
          NotesAndTagsSection(
            initialNotes: card.notes,
            initialTags: card.tags,
            onNotesChanged: (v) => _c.updateCardField('notes', v),
            onTagsChanged: (v) => _c.updateCardField('tags', v),
          ),
          const SizedBox(height: 20),
          CwTrustLine('cwEncryptedLocal'.tr()),
          const SizedBox(height: 8),
        ],
      );
    });
  }
}
