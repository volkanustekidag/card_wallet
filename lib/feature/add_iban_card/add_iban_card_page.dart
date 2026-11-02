import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/core/widgets/notes_and_tags_section.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/scanner/live_scanner_page.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/components/cw_form.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';

/// Add / edit an IBAN. The IBAN is checked (mod-97, per-country length)
/// as you type and fills in the bank when the bank code is known.
/// [prefill] comes from the live scanner.
class AddIbanCardPage extends StatefulWidget {
  final IbanCard? ibanCard;
  final IbanHit? prefill;

  const AddIbanCardPage({Key? key, this.ibanCard, this.prefill})
      : super(key: key);

  @override
  State<AddIbanCardPage> createState() => _AddIbanCardPageState();
}

class _AddIbanCardPageState extends State<AddIbanCardPage> {
  late final AddIbanCardController _c = Get.find<AddIbanCardController>();
  final _iban = TextEditingController();
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _swift = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.ibanCard != null) {
      _c.initializeForEdit(widget.ibanCard!);
    } else {
      _c.initializeForCreate();
    }
    final card = _c.currentCard.value;
    _iban.text = formatIban(card.iban);
    _holder.text = card.cardHolder;
    _bank.text = card.bankName;
    _swift.text = card.swiftCode;
    if (widget.prefill != null) _apply(widget.prefill!);
  }

  @override
  void dispose() {
    for (final t in [_iban, _holder, _bank, _swift]) {
      t.dispose();
    }
    super.dispose();
  }

  void _apply(IbanHit hit) {
    _iban.text = formatIban(hit.iban);
    _onIban(_iban.text);
    if (hit.holder != null && hit.holder!.isNotEmpty) {
      _holder.text = hit.holder!;
      _c.updateCardField('cardHolder', hit.holder!);
    }
    if (hit.bic != null && hit.bic!.isNotEmpty) {
      _swift.text = hit.bic!;
      _c.updateCardField('swiftCode', hit.bic!);
    }
  }

  void _onIban(String v) {
    _c.updateCardField('iban', v);
    final detected = CardBankDetector.detectFromIban(v);
    if (detected != null && _bank.text != detected) {
      _bank.text = detected;
      _c.updateCardField('bankName', detected);
    }
  }

  Future<void> _scan() async {
    final hit = await Navigator.of(context).push<ScanHit>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const LiveScannerPage(
        initialMode: ScanMode.iban,
        returnHit: true,
      ),
    ));
    if (hit is IbanHit && mounted) setState(() => _apply(hit));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final card = _c.currentCard.value;
      final editing = _c.isEditMode.value;
      final clean = card.iban.replaceAll(RegExp(r'\s'), '').toUpperCase();
      Widget? status;
      if (clean.length >= 15) {
        status = IbanValidator.isValid(clean)
            ? CwNotice.ok(
                context, 'cwIbanValid'.tr(args: [clean.substring(0, 2)]))
            : CwNotice.warn(context, 'cwIbanInvalid'.tr());
      }
      return CwFormScaffold(
        title: editing ? 'cwEditIban'.tr() : 'cwNewIban'.tr(),
        action: editing
            ? null
            : CwHeaderAction(
                icon: CwIcons.scan, label: 'cwScan'.tr(), onTap: _scan),
        preview: WalletCardFace(item: WalletItem.iban(card)),
        button: CwButton(
          editing ? 'cwSave'.tr() : 'cwAddCard'.tr(),
          loading: _c.isLoading.value,
          onPressed: _c.canSave && !_c.isLoading.value
              ? () => _c.saveCard()
              : null,
        ),
        children: [
          CwField(
            controller: _iban,
            label: 'IBAN',
            hint: 'DE89 3704 0044 0532 0130 00',
            mono: true,
            autofocus: !editing && widget.prefill == null,
            textCapitalization: TextCapitalization.characters,
            maxLength: 42,
            inputFormatters: [_IbanFormatter()],
            onChanged: _onIban,
          ),
          if (status != null) ...[const SizedBox(height: 10), status],
          const SizedBox(height: 10),
          CwField(
            controller: _holder,
            label: 'cwHolderIban'.tr(),
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            onChanged: (v) => _c.updateCardField('cardHolder', v),
          ),
          const SizedBox(height: 10),
          CwField(
            controller: _bank,
            label: 'cwBank'.tr(),
            hint: 'unknownBank'.tr(),
            maxLength: 40,
            onChanged: (v) => _c.updateCardField('bankName', v),
          ),
          const SizedBox(height: 10),
          CwField(
            controller: _swift,
            label: 'cwSwiftField'.tr(),
            mono: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              _UpperFormatter(),
            ],
            onChanged: (v) => _c.updateCardField('swiftCode', v),
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
        ],
      );
    });
  }
}

/// Upper-cases, drops anything but letters/digits and groups by four.
class _IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final clean =
        newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final grouped = formatIban(clean);
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }
}

class _UpperFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
