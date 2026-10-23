import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card_page.dart';
import 'package:wallet_app/feature/card_detail/detail_chrome.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_card_utils.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_share_flow.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_top_bar.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';

/// IBAN detail: the account card, each field one tap from the clipboard,
/// and sharing as image or text.
class IbanPage extends StatefulWidget {
  final IbanCard card;

  const IbanPage({super.key, required this.card});

  @override
  State<IbanPage> createState() => _IbanPageState();
}

class _IbanPageState extends State<IbanPage> {
  /// Re-read after an edit: saving stores a new object under the card's id.
  late IbanCard _card = widget.card;
  IbanCard get card => _card;

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final item = WalletItem.iban(card);
    final notes = card.notes?.trim() ?? '';
    final swift = card.swiftCode.trim().toUpperCase();
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
                  child: WalletCardFace(item: item, interactive: true),
                ),
                const SizedBox(height: 14),
                CwGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    _FieldRow(
                      label: 'IBAN',
                      value: formatIban(card.iban),
                      copy: card.iban.replaceAll(' ', '').toUpperCase(),
                      mono: true,
                    ),
                    if (swift.isNotEmpty)
                      _FieldRow(
                        label: 'BIC / SWIFT',
                        value: swift,
                        copy: swift,
                        mono: true,
                      ),
                    if (card.cardHolder.trim().isNotEmpty)
                      _FieldRow(
                        label: 'cwAccountHolder'.tr(),
                        value: card.cardHolder.trim(),
                        copy: card.cardHolder.trim(),
                      ),
                    if (card.bankName.trim().isNotEmpty)
                      _FieldRow(
                        label: 'cwBank'.tr(),
                        value: card.bankName.trim(),
                        copy: card.bankName.trim(),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CwButton(
                        'cwShareIban'.tr(),
                        icon: CwIcons.share,
                        height: 50,
                        onPressed: () => shareIban(context, card),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CwCircleButton(
                      CwIcons.qr,
                      size: 50,
                      semanticLabel: 'qrCode'.tr(),
                      onPressed: () => IbanCardUtils.showQRFullScreen(
                        context,
                        qrData: card.iban,
                        beneficiaryName: card.cardHolder,
                        card: card,
                      ),
                    ),
                  ],
                ),
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
              leading: CwIcon(CwIcons.edit, color: c.ink),
              title: 'cwEdit'.tr(),
              onTap: () {
                Navigator.pop(sheet);
                _edit();
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

  /// Edits on top of this page and comes back to it, updated.
  Future<void> _edit() async {
    await Get.to<void>(
      () => AddIbanCardPage(ibanCard: card),
      binding: AddIbanCardBindings(),
    );
    final cards = await IbanCardService().getAllIbanCards();
    final fresh = cards.where((c) => c.id == card.id).firstOrNull;
    if (fresh != null && mounted) setState(() => _card = fresh);
  }

  Future<void> _delete() async {
    final ok = await showConfirmActionSheet(
      context: context,
      title: 'deleteIbanCard'.tr(),
      content: 'deleteDataMessage'.tr(),
    );
    if (!ok) return;
    await Get.find<IbanCardController>().removeIbanCard(card);
    if (mounted) Navigator.of(context).pop();
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String copy;
  final bool mono;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.copy,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return InkWell(
      onTap: () =>
          copySensitive(context, copy, cardType: AnalyticsCardType.iban),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: CwType.footnote.copyWith(color: c.mute)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: mono
                        ? CwType.mono(size: 15, color: c.ink)
                        : CwType.body.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'cwCopy'.tr(),
              child: CwIcon(CwIcons.copy, size: 18, color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}
