import 'package:easy_localization/easy_localization.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';
import 'package:wallet_app/core/utils/share_origin.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/iban_card_face.dart';
import 'package:wallet_app/core/widgets/sheet_action_bar.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card_page.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_card_utils.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/utils/loyalty_wallet_action.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/shareable_loyalty_card.dart';

/// Open the unified card detail sheet. Slides up as a draggable modal
/// bottom sheet so the home stays visible behind it (Apple Wallet feel).
/// The Hero tag carries continuity from the carousel card visual.
Future<void> showCardDetailSheet(BuildContext context, WalletItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => CardDetailSheet(item: item),
  );
}

/// Per-kind comprehensive detail surface. Renders a hero card visual at
/// the top, then the full set of fields (with copy / reveal where it makes
/// sense), notes, and a footer with Share / Edit / Delete. Drives the
/// shared "tap card → see everything" interaction across home, recent
/// list and the all-cards browser.
class CardDetailSheet extends StatefulWidget {
  final WalletItem item;
  const CardDetailSheet({Key? key, required this.item}) : super(key: key);

  @override
  State<CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<CardDetailSheet> {
  bool _favoriteDirty = false;

  bool get _isFavorite => isFavoriteCard(widget.item.card);

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    toggleFavoriteTag(widget.item.card);
    setState(() => _favoriteDirty = !_favoriteDirty);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoyalty = widget.item.kind == WalletItemKind.loyalty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isLoyalty ? Colors.transparent : colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: _buildBody(scrollController),
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    switch (widget.item.kind) {
      case WalletItemKind.credit:
        return _CreditDetailBody(
          card: widget.item.card as CreditCard,
          heroTag: widget.item.heroTag,
          isFavorite: _isFavorite,
          onToggleFavorite: _toggleFavorite,
          scrollController: scrollController,
        );
      case WalletItemKind.iban:
        return _IbanDetailBody(
          card: widget.item.card as IbanCard,
          heroTag: widget.item.heroTag,
          isFavorite: _isFavorite,
          onToggleFavorite: _toggleFavorite,
          scrollController: scrollController,
        );
      case WalletItemKind.loyalty:
        return _LoyaltyDetailBody(
          card: widget.item.card as LoyaltyCard,
          heroTag: widget.item.heroTag,
          isFavorite: _isFavorite,
          onToggleFavorite: _toggleFavorite,
          scrollController: scrollController,
        );
    }
  }
}

// =============================================================================
// Shared chrome
// =============================================================================

class _SheetHandle extends StatelessWidget {
  final bool onDark;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onClose;
  const _SheetHandle({
    this.onDark = false,
    required this.isFavorite,
    required this.onFavorite,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dragColor = onDark
        ? Colors.white.withValues(alpha: 0.45)
        : colorScheme.onSurface.withValues(alpha: 0.18);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpaceLg, kSpaceMd, kSpaceLg, 0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: dragColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: kSpaceSm),
          Row(
            children: [
              const Spacer(),
              _ChromeIconButton(
                icon:
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                iconColor: isFavorite ? const Color(0xFFFFB800) : null,
                onDark: onDark,
                onTap: onFavorite,
              ),
              const SizedBox(width: 8),
              _ChromeIconButton(
                icon: Icons.close_rounded,
                onDark: onDark,
                onTap: onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final bool onDark;
  final VoidCallback onTap;
  const _ChromeIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.18)
        : colorScheme.surfaceContainerHighest;
    final fg = iconColor ??
        (onDark ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.78));
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool onDark;
  const _SectionHeader({required this.label, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: kSpaceSm),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: onDark
              ? Colors.white.withValues(alpha: 0.7)
              : colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String copyValue;
  final bool isFirst;
  final bool isLast;
  final Widget? trailing;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.copyValue,
    this.isFirst = false,
    this.isLast = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        SensitiveClipboard.copy(copyValue);
        Get.context?.showSuccessSnackBar('detailFieldCopied');
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.copy_rounded,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _RevealToggle extends StatelessWidget {
  final bool revealed;
  final VoidCallback onTap;
  const _RevealToggle({required this.revealed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  final String notes;
  final bool onDark;
  const _NotesPanel({required this.notes, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.18)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.25))
            : null,
      ),
      child: Text(
        notes,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: onDark
              ? Colors.white.withValues(alpha: 0.92)
              : colorScheme.onSurface.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final List<Widget> rows;
  const _FieldGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 14,
            endIndent: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}


/// Full-width "Add to Wallet" button for loyalty sheet. Sits on top of the
/// gradient backdrop, mirrors the detail page's glass styling so the entry
/// point feels identical across surfaces.
class _WalletAddButton extends StatefulWidget {
  final String label;
  final String? assetIcon;
  final VoidCallback onTap;
  const _WalletAddButton({
    required this.label,
    required this.onTap,
    this.assetIcon,
  });

  @override
  State<_WalletAddButton> createState() => _WalletAddButtonState();
}

class _WalletAddButtonState extends State<_WalletAddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          onHighlightChanged: (v) => setState(() => _down = v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.assetIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.asset(
                      widget.assetIcon!,
                      width: 22,
                      height: 22,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Credit detail
// =============================================================================

class _CreditDetailBody extends StatefulWidget {
  final CreditCard card;
  final String heroTag;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final ScrollController scrollController;

  const _CreditDetailBody({
    required this.card,
    required this.heroTag,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.scrollController,
  });

  @override
  State<_CreditDetailBody> createState() => _CreditDetailBodyState();
}

class _CreditDetailBodyState extends State<_CreditDetailBody> {
  bool _numberRevealed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width * 0.84).clamp(260.0, 380.0);
    final cardHeight = cardWidth / 1.586;
    final number = widget.card.creditCardNumber;
    final masked = _maskNumber(number);

    return Container(
      color: colorScheme.surface,
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          _SheetHandle(
            isFavorite: widget.isFavorite,
            onFavorite: widget.onToggleFavorite,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: kSpaceMd),
          Center(
            child: Hero(
              tag: widget.heroTag,
              createRectTween: (begin, end) =>
                  MaterialRectArcTween(begin: begin, end: end),
              child: Material(
                color: Colors.transparent,
                // Vertical breathing room so the FlipCard's 3D rotation
                // (projects ~%15 past the static rect on each axis) lands
                // here instead of being shaved at the apex frame. The
                // ClipRRect that used to wrap FlipCard is gone — each face
                // self-rounds its corners via CreditCardFront/Back.
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: cardHeight * 0.12),
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: FlipCard(
                      direction: FlipDirection.HORIZONTAL,
                      speed: 600,
                      flipOnTouch: true,
                      front: CreditCardFront(
                        creditCard: widget.card,
                        maskNumber: true,
                      ),
                      back: CreditCardBack(creditCard: widget.card),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: kSpaceSm),
          Center(
            child: Text(
              'cardDetailFlipHint'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: kSpaceLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(label: 'detailCardInfo'.tr()),
                _FieldGroup(
                  rows: [
                    _FieldRow(
                      label: 'fieldNumber'.tr(),
                      value: _numberRevealed
                          ? _formatGroupedNumber(number)
                          : masked,
                      copyValue: number.replaceAll(' ', ''),
                      isFirst: true,
                      trailing: _RevealToggle(
                        revealed: _numberRevealed,
                        onTap: () => setState(
                          () => _numberRevealed = !_numberRevealed,
                        ),
                      ),
                    ),
                    _FieldRow(
                      label: 'fieldHolder'.tr(),
                      value: widget.card.cardHolder.isNotEmpty
                          ? widget.card.cardHolder
                          : '—',
                      copyValue: widget.card.cardHolder,
                    ),
                    _FieldRow(
                      label: 'fieldExpiry'.tr(),
                      value: widget.card.expirationDate.isNotEmpty
                          ? widget.card.expirationDate
                          : '—',
                      copyValue: widget.card.expirationDate,
                    ),
                    _FieldRow(
                      label: 'fieldBank'.tr(),
                      value: widget.card.bankName.isNotEmpty
                          ? widget.card.bankName
                          : '—',
                      copyValue: widget.card.bankName,
                      isLast: true,
                    ),
                  ],
                ),
                if (widget.card.notes != null &&
                    widget.card.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: kSpaceLg),
                  _SectionHeader(label: 'detailNotes'.tr()),
                  _NotesPanel(notes: widget.card.notes!),
                ],
                const SizedBox(height: kSpaceXL),
                SheetActionBar(
                  actions: [
                    SheetAction(
                      icon: Icons.ios_share_rounded,
                      label: 'actShare'.tr(),
                      onTap: () => _share(context),
                    ),
                    SheetAction(
                      icon: Icons.edit_rounded,
                      label: 'detailEdit'.tr(),
                      onTap: () => _edit(context),
                    ),
                    SheetAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'delete'.tr(),
                      onTap: () => _delete(context),
                      destructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: kSpaceLg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _maskNumber(String raw) {
    final clean = raw.replaceAll(' ', '');
    if (clean.length < 4) return raw;
    final tail = clean.substring(clean.length - 4);
    return '•••• •••• •••• $tail';
  }

  String _formatGroupedNumber(String raw) {
    final clean = raw.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  Future<void> _share(BuildContext context) async {
    final c = widget.card;
    final text =
        '${c.bankName} • ${c.creditCardNumber} • ${c.cardHolder} • ${c.expirationDate}';
    await Share.share(
      text,
      sharePositionOrigin: shareOriginFromContext(context),
    );
  }

  void _edit(BuildContext context) {
    Navigator.of(context).pop();
    Get.to(
      () => AddCreditCardPage(creditCard: widget.card),
      binding: AddCreditCardBindings(),
    );
  }

  void _delete(BuildContext context) {
    showConfirmActionSheet(
      context: context,
      title: 'deleteCreditCard'.tr(),
      content: 'deleteDataMessage'.tr(),
      onConfirm: () async {
        final controller = Get.find<CreditCardController>();
        await controller.removeCreditCard(widget.card);
        Get.back();
        if (mounted) Navigator.of(context).pop();
      },
    );
  }
}

// =============================================================================
// IBAN detail
// =============================================================================

class _IbanDetailBody extends StatefulWidget {
  final IbanCard card;
  final String heroTag;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final ScrollController scrollController;

  const _IbanDetailBody({
    required this.card,
    required this.heroTag,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.scrollController,
  });

  @override
  State<_IbanDetailBody> createState() => _IbanDetailBodyState();
}

class _IbanDetailBodyState extends State<_IbanDetailBody> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width * 0.84).clamp(260.0, 380.0);
    final cardHeight = cardWidth / 1.586;
    final iban = _formatIban(widget.card.iban);
    final isPrimary = widget.card.id == 1;

    return Container(
      color: colorScheme.surface,
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          _SheetHandle(
            isFavorite: widget.isFavorite,
            onFavorite: widget.onToggleFavorite,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: kSpaceMd),
          Center(
            child: Hero(
              tag: widget.heroTag,
              createRectTween: (begin, end) =>
                  MaterialRectArcTween(begin: begin, end: end),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: IbanCardFace(
                    card: widget.card,
                    boxShadow: kCardShadow,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: kSpaceLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(label: 'accountInfo'.tr()),
                _FieldGroup(
                  rows: [
                    _FieldRow(
                      label: 'fieldHolder'.tr(),
                      value: widget.card.cardHolder.isNotEmpty
                          ? widget.card.cardHolder
                          : '—',
                      copyValue: widget.card.cardHolder,
                      isFirst: true,
                    ),
                    _FieldRow(
                      label: 'fieldIban'.tr(),
                      value: iban,
                      copyValue: widget.card.iban.replaceAll(' ', ''),
                    ),
                    _FieldRow(
                      label: 'fieldSwift'.tr(),
                      value: widget.card.swiftCode.isNotEmpty
                          ? widget.card.swiftCode
                          : '—',
                      copyValue: widget.card.swiftCode,
                    ),
                    _FieldRow(
                      label: 'fieldBank'.tr(),
                      value: widget.card.bankName.isNotEmpty
                          ? widget.card.bankName
                          : '—',
                      copyValue: widget.card.bankName,
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: kSpaceLg),
                _SectionHeader(label: 'qrCode'.tr()),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: widget.card.iban,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _qrFullscreen(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.fullscreen_rounded,
                                size: 18,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'detailQrFullscreen'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.card.notes != null &&
                    widget.card.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: kSpaceLg),
                  _SectionHeader(label: 'detailNotes'.tr()),
                  _NotesPanel(notes: widget.card.notes!),
                ],
                const SizedBox(height: kSpaceXL),
                SheetActionBar(
                  actions: [
                    SheetAction(
                      icon: Icons.ios_share_rounded,
                      label: 'actShare'.tr(),
                      onTap: () => _share(context),
                    ),
                    if (!isPrimary)
                      SheetAction(
                        icon: Icons.edit_rounded,
                        label: 'detailEdit'.tr(),
                        onTap: () => _edit(context),
                      ),
                    SheetAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'delete'.tr(),
                      onTap: () => _delete(context),
                      destructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: kSpaceLg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatIban(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final buffer = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  Future<void> _share(BuildContext context) async {
    final c = widget.card;
    final text = '${c.bankName}\nIBAN: ${c.iban}\n${c.cardHolder}';
    await Share.share(
      text,
      sharePositionOrigin: shareOriginFromContext(context),
    );
  }

  void _qrFullscreen(BuildContext context) {
    Navigator.of(context).pop();
    IbanCardUtils.showQRFullScreen(
      context,
      qrData: widget.card.iban,
      beneficiaryName: widget.card.cardHolder,
    );
  }

  void _edit(BuildContext context) {
    Navigator.of(context).pop();
    Get.to(
      () => AddIbanCardPage(ibanCard: widget.card),
      binding: AddIbanCardBindings(),
    );
  }

  void _delete(BuildContext context) {
    showConfirmActionSheet(
      context: context,
      title: 'deleteIbanCard'.tr(),
      content: 'deleteDataMessage'.tr(),
      onConfirm: () async {
        final controller = Get.find<IbanCardController>();
        controller.removeIbanCard(widget.card);
        Get.back();
        if (mounted) Navigator.of(context).pop();
      },
    );
  }
}

// =============================================================================
// Loyalty detail
// =============================================================================

class _LoyaltyDetailBody extends StatefulWidget {
  final LoyaltyCard card;
  final String heroTag;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final ScrollController scrollController;

  const _LoyaltyDetailBody({
    required this.card,
    required this.heroTag,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.scrollController,
  });

  @override
  State<_LoyaltyDetailBody> createState() => _LoyaltyDetailBodyState();
}

class _LoyaltyDetailBodyState extends State<_LoyaltyDetailBody> {
  @override
  Widget build(BuildContext context) {
    final gradients = LinearGradients().linearGradientList;
    final gradient =
        gradients[widget.card.colorId.clamp(0, gradients.length - 1)];
    final brand = (widget.card.brand?.isNotEmpty ?? false)
        ? widget.card.brand!
        : widget.card.name;
    final hasLogo = LoyaltyBrandResolver.domainFor(brand) != null ||
        (widget.card.website?.isNotEmpty ?? false);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          _SheetHandle(
            onDark: true,
            isFavorite: widget.isFavorite,
            onFavorite: widget.onToggleFavorite,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: kSpaceLg),
          Center(
            child: Hero(
              tag: widget.heroTag,
              createRectTween: (begin, end) =>
                  MaterialRectArcTween(begin: begin, end: end),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: kSpaceLg),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (hasLogo)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: BankLogo(
                            loyaltyBrand: brand,
                            domain: widget.card.website,
                            size: 40,
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            if (brand.isNotEmpty &&
                                brand != widget.card.name) ...[
                              const SizedBox(height: 2),
                              Text(
                                brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: kSpaceLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpaceLg,
                    vertical: kSpaceLg,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      BarcodeRenderer(
                        data: widget.card.barcode,
                        format: widget.card.barcodeFormat,
                        qrSize: 220,
                        barcodeHeight: 130,
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _copyBarcode,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _formatBarcodeText(widget.card.barcode),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1D24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.card.barcodeFormat == 'QR_CODE'
                            ? 'QR CODE'
                            : widget.card.barcodeFormat.replaceAll('_', ' '),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                          color: const Color(0xFF1A1D24).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.card.notes != null &&
                    widget.card.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: kSpaceLg),
                  _SectionHeader(label: 'detailNotes'.tr(), onDark: true),
                  _NotesPanel(notes: widget.card.notes!, onDark: true),
                ],
                const SizedBox(height: kSpaceLg),
                _WalletAddButton(
                  label: loyaltyWalletActionLabel(context),
                  assetIcon: loyaltyWalletActionAsset(context),
                  onTap: () => addLoyaltyCardToWallet(context, widget.card),
                ),
                const SizedBox(height: kSpaceMd),
                SheetActionBar(
                  onDark: true,
                  actions: [
                    SheetAction(
                      icon: Icons.ios_share_rounded,
                      label: 'actShare'.tr(),
                      onTap: () => _share(context),
                    ),
                    SheetAction(
                      icon: Icons.edit_rounded,
                      label: 'detailEdit'.tr(),
                      onTap: () => _edit(context),
                    ),
                    SheetAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'delete'.tr(),
                      onTap: () => _delete(context),
                    ),
                  ],
                ),
                const SizedBox(height: kSpaceLg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBarcodeText(String raw) {
    if (raw.length <= 4) return raw;
    final chars = raw.split('');
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(chars[i]);
    }
    return buffer.toString();
  }

  void _copyBarcode() {
    HapticFeedback.lightImpact();
    SensitiveClipboard.copy(widget.card.barcode);
    Get.context?.showSuccessSnackBar('detailFieldCopied');
  }

  Future<void> _share(BuildContext context) async {
    final card = widget.card;
    final brandLogo =
        await ShareableLoyaltyCard.precacheBrandLogo(context, card);
    if (!context.mounted) return;
    await shareWidgetAsImage(
      context: context,
      widget: ShareableLoyaltyCard(
        card: card,
        brandLogoImage: brandLogo,
      ),
      size: const Size(
        ShareableLoyaltyCard.width,
        ShareableLoyaltyCard.height,
      ),
      filename: 'loyalty-${card.id}.png',
    );
  }

  void _edit(BuildContext context) {
    Navigator.of(context).pop();
    Get.to(
      () => AddLoyaltyCardPage(card: widget.card),
      binding: AddLoyaltyCardBindings(),
    );
  }

  void _delete(BuildContext context) {
    showConfirmActionSheet(
      context: context,
      title: 'deleteCard'.tr(),
      content: 'deleteDataMessage'.tr(),
      onConfirm: () async {
        final controller = Get.find<LoyaltyCardController>();
        await controller.removeLoyaltyCard(widget.card);
        if (mounted) Navigator.of(context).pop();
      },
    );
  }
}
