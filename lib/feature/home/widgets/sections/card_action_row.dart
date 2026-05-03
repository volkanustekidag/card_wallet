import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:share_plus/share_plus.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/utils/share_origin.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_kind.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sheets/card_detail_sheet.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/shareable_loyalty_card.dart';

/// Dark glass-morphism action panel sitting under the featured card. Show /
/// Copy / Share / More all act on whichever card is currently focused in
/// the carousel. When the wallet is empty the row dims and explains why.
class CardActionRow extends StatelessWidget {
  final WalletItem? activeItem;

  const CardActionRow({Key? key, this.activeItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = activeItem == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLg,
        kSpaceSm,
        kSpaceLg,
        kSpaceSm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpaceMd,
          vertical: kSpaceMd,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: disabled ? 0.6 : 1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.remove_red_eye_rounded,
                label: 'actShow'.tr(),
                onTap: disabled ? null : () => _onShow(context),
              ),
            ),
            Expanded(
              child: _ActionButton(
                icon: Icons.copy_rounded,
                label: 'actCopy'.tr(),
                onTap: disabled ? null : () => _onCopy(context),
              ),
            ),
            Expanded(
              child: _ActionButton(
                icon: Icons.ios_share_rounded,
                label: 'actShare'.tr(),
                onTap: disabled ? null : () => _onShare(context),
              ),
            ),
            Expanded(
              child: _ActionButton(
                icon: Icons.more_horiz_rounded,
                label: 'actMore'.tr(),
                onTap: disabled ? null : () => _onMore(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onShow(BuildContext context) {
    HapticFeedback.lightImpact();
    showCardDetailSheet(context, activeItem!);
  }

  Future<void> _onCopy(BuildContext context) async {
    HapticFeedback.lightImpact();
    final text = _shareText(activeItem!);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    context.showSuccessSnackBar('cardCopied');
  }

  Future<void> _onShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    // Loyalty cards share as a print-quality PNG so the receiver can scan
    // the barcode straight from the image. Other kinds keep the plain-text
    // share — IBAN and credit numbers are sensitive enough that we don't
    // want to encourage shipping them as graphics.
    if (activeItem!.kind == WalletItemKind.loyalty) {
      final card = activeItem!.card as LoyaltyCard;
      // Resolve the brand logo upfront so we can inject the [ImageProvider]
      // straight into the off-screen widget. Going through CachedNetworkImage
      // at snapshot time produced washed-out logos in the exported PNG.
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
      return;
    }
    final text = _shareText(activeItem!);
    await Share.share(text, sharePositionOrigin: shareOriginFromContext(context));
  }

  void _onMore(BuildContext context, ColorScheme colorScheme) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpaceLg,
              vertical: kSpaceMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: kSpaceMd),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _SheetTile(
                  icon: Icons.list_alt_rounded,
                  label: 'viewAll'.tr(),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Get.toNamed(_routeFor(activeItem!.kind));
                  },
                ),
                _SheetTile(
                  icon: Icons.copy_rounded,
                  label: 'actCopy'.tr(),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _onCopy(context);
                  },
                ),
                _SheetTile(
                  icon: Icons.ios_share_rounded,
                  label: 'actShare'.tr(),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _onShare(context);
                  },
                ),
                const SizedBox(height: kSpaceSm),
              ],
            ),
          ),
        );
      },
    );
  }

  String _routeFor(WalletItemKind kind) {
    switch (kind) {
      case WalletItemKind.credit:
        return HomeCardKind.credit.listRoute;
      case WalletItemKind.iban:
        return HomeCardKind.iban.listRoute;
      case WalletItemKind.loyalty:
        return HomeCardKind.loyalty.listRoute;
    }
  }

  String _shareText(WalletItem item) {
    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        return '${c.bankName} • ${c.creditCardNumber} • ${c.cardHolder} • ${c.expirationDate}';
      case WalletItemKind.iban:
        final c = item.card as IbanCard;
        return '${c.bankName}\nIBAN: ${c.iban}\n${c.cardHolder}';
      case WalletItemKind.loyalty:
        final c = item.card as LoyaltyCard;
        final brand = (c.brand?.isNotEmpty ?? false) ? c.brand! : c.name;
        return '$brand • ${c.barcode}';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    final iconColor =
        colorScheme.onSurface.withValues(alpha: disabled ? 0.32 : 0.85);
    final labelColor =
        colorScheme.onSurface.withValues(alpha: disabled ? 0.4 : 0.78);
    final platePlateColor =
        colorScheme.onSurface.withValues(alpha: disabled ? 0.04 : 0.08);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: platePlateColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetTile({
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceSm,
            vertical: kSpaceMd,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: kSpaceMd),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
