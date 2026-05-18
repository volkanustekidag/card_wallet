import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_animations.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sheets/card_detail_sheet.dart';

/// Compact list shown under the filter chips. One row per card, regardless
/// of kind: a small chrome badge on the left (mini visa-card / IBAN tag /
/// brand chip), a title + subtitle, an optional favourite star, and a
/// chevron. Caps at 5 rows so the page doesn't grow indefinitely; tapping
/// a row opens the unified detail sheet, "View All" jumps to the unified
/// browser at /allCards.
///
/// Reverse-parallax: when [scrollOffset] reaches the bottom-focus
/// thresholds the container, header and rows inflate so the panel
/// "wakes up" as the user scrolls into it.
class RecentCardsList extends StatelessWidget {
  final List<WalletItem> items;
  final HomeFilter activeFilter;
  final int maxRows;
  final ValueNotifier<double>? scrollOffset;

  const RecentCardsList({
    Key? key,
    required this.items,
    this.activeFilter = HomeFilter.all,
    this.maxRows = 5,
    this.scrollOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (scrollOffset == null) return _buildAt(context, 0);
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset!,
      builder: (context, value, _) {
        return _buildAt(context, bottomPanelProminence(value));
      },
    );
  }

  Widget _buildAt(BuildContext context, double prominence) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = items.where(activeFilter.matches).toList();
    final visible = filtered.take(maxRows).toList();

    final headerSize = 15 + 3 * prominence;
    final radius = 18 + 6 * prominence;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        kSpaceLg,
        0,
        kSpaceLg,
        kSpaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: Row(
              children: [
                Text(
                  activeFilter == HomeFilter.favorites
                      ? 'filterFavorites'.tr()
                      : 'recentCards'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: headerSize,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                _ViewAllLink(
                  onTap: () => _viewAll(activeFilter),
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            _EmptyHint(filter: activeFilter)
          else
            AnimatedContainer(
              duration: kFastAnim,
              curve: kHomeCurve,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: prominence > 0
                    ? [
                        BoxShadow(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.04 + 0.06 * prominence),
                          blurRadius: 14 * prominence,
                          offset: Offset(0, 6 * prominence),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    // Key on the item's hero tag only — the staggered
                    // entrance plays once when the row first mounts and
                    // does NOT replay on filter switches.
                    KeyedSubtree(
                      key: ValueKey(visible[i].heroTag),
                      child: _RowTile(
                        item: visible[i],
                        isFirst: i == 0,
                        isLast: i == visible.length - 1,
                        prominence: prominence,
                        cornerRadius: radius,
                      ),
                    ),
                    if (i < visible.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 60,
                        endIndent: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.06),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _viewAll(HomeFilter filter) {
    HapticFeedback.selectionClick();
    _openAllCards(filter);
  }
}

void _openAllCards(HomeFilter filter) {
  Get.toNamed(
    '/allCards',
    arguments: {'filter': filter},
  );
}

class _ViewAllLink extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'viewAll'.tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowTile extends StatefulWidget {
  final WalletItem item;
  final bool isFirst;
  final bool isLast;
  final double prominence;
  final double cornerRadius;
  const _RowTile({
    Key? key,
    required this.item,
    required this.isFirst,
    this.isLast = false,
    this.prominence = 0,
    this.cornerRadius = 18,
  }) : super(key: key);

  @override
  State<_RowTile> createState() => _RowTileState();
}

class _RowTileState extends State<_RowTile>
    with SingleTickerProviderStateMixin {
  // Bumps every tap so the chevron-nudge re-runs each time.
  int _tapTrigger = 0;
  // Slide-out reveal driven by long-press. 0 = collapsed, 1 = fully open.
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  bool get _revealed => _revealController.value > 0.5;

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _toggleReveal() {
    HapticFeedback.mediumImpact();
    if (_revealed) {
      _revealController.reverse();
    } else {
      _revealController.forward();
    }
  }

  void _onTap() {
    if (_revealed) {
      _revealController.reverse();
      return;
    }
    setState(() => _tapTrigger += 1);
    HapticFeedback.selectionClick();
    // Small delay so the chevron nudge animates before the sheet covers
    // the row.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      showCardDetailSheet(context, widget.item);
    });
  }

  void _toggleFavorite() {
    final nowFav = toggleFavoriteTag(widget.item.card);
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {});
      context.showSuccessSnackBar(
        nowFav ? 'favoriteAdded'.tr() : 'favoriteRemoved'.tr(),
      );
    }
    _revealController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = widget.item.isFavorite;
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_revealController.value);
        return Stack(
          children: [
            // Action layer revealed underneath as the row slides left.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kSpaceSm,
                  horizontal: kSpaceSm,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: t,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RevealAction(
                          icon: isFav
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFFB800),
                          onTap: _toggleFavorite,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-60 * t, 0),
              child: child,
            ),
          ],
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          onLongPress: _toggleReveal,
          borderRadius: BorderRadius.vertical(
            top: widget.isFirst
                ? Radius.circular(widget.cornerRadius)
                : Radius.zero,
            bottom: widget.isLast
                ? Radius.circular(widget.cornerRadius)
                : Radius.zero,
          ),
          child: Container(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSpaceMd + kSpaceXS * widget.prominence,
                vertical: kSpaceSm + 2 + kSpaceXS * widget.prominence,
              ),
              child: Row(
                children: [
                  _ChromeBadge(
                    item: widget.item,
                    prominence: widget.prominence,
                  ),
                  SizedBox(width: kSpaceMd + 2 * widget.prominence),
                  Expanded(
                    child: _TitleBlock(
                      item: widget.item,
                      prominence: widget.prominence,
                    ),
                  ),
                  ChevronNudge(
                    trigger: _tapTrigger,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 18 + 2 * widget.prominence,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RevealAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _ChromeBadge extends StatelessWidget {
  final WalletItem item;
  final double prominence;
  const _ChromeBadge({required this.item, this.prominence = 0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = 36 + 4 * prominence;
    final radius = 10 + 2 * prominence;
    final iconBoxSize = 18 + 2 * prominence;
    final logoSize = 22 + 2 * prominence;
    Color background;
    IconData icon;
    Color iconColor;
    Widget? logo;

    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        background = colorScheme.primary.withValues(alpha: 0.12);
        iconColor = colorScheme.primary;
        icon = Icons.credit_card_rounded;
        final detected = CardBankDetector.detect(c.creditCardNumber);
        if (CardBankDetector.bankDomainFor(detected) != null ||
            CardBankDetector.bankDomainFor(c.bankName) != null) {
          logo = BankLogo(
            cardNumber: c.creditCardNumber,
            bankName: c.bankName,
            size: logoSize,
          );
        }
        break;
      case WalletItemKind.iban:
        final c = item.card as IbanCard;
        background = colorScheme.secondary.withValues(alpha: 0.12);
        iconColor = colorScheme.secondary;
        icon = Icons.account_balance_rounded;
        final detected = CardBankDetector.detectFromIban(c.iban);
        if (CardBankDetector.bankDomainFor(detected) != null ||
            CardBankDetector.bankDomainFor(c.bankName) != null) {
          logo = BankLogo(
            iban: c.iban,
            bankName: c.bankName,
            size: logoSize,
          );
        }
        break;
      case WalletItemKind.loyalty:
        final c = item.card as LoyaltyCard;
        background = colorScheme.tertiary.withValues(alpha: 0.12);
        iconColor = colorScheme.tertiary;
        icon = Icons.local_offer_rounded;
        final brand = (c.brand?.isNotEmpty ?? false) ? c.brand! : c.name;
        if (LoyaltyBrandResolver.domainFor(brand) != null ||
            (c.website?.isNotEmpty ?? false)) {
          logo = BankLogo(
            loyaltyBrand: brand,
            domain: c.website,
            size: logoSize,
          );
        }
        break;
    }

    if (logo != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        padding: const EdgeInsets.all(5),
        child: logo,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: iconColor, size: iconBoxSize),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final WalletItem item;
  final double prominence;
  const _TitleBlock({required this.item, this.prominence = 0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String title;
    String subtitle;
    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        title = c.bankName.isNotEmpty ? c.bankName : 'creditCardLabel'.tr();
        subtitle = 'creditCardLabel'.tr();
        break;
      case WalletItemKind.iban:
        final c = item.card as IbanCard;
        title = _maskedIban(c.iban);
        subtitle = c.bankName.isNotEmpty
            ? '${c.bankName} • ${c.cardHolder}'
            : 'primaryIban'.tr();
        break;
      case WalletItemKind.loyalty:
        final c = item.card as LoyaltyCard;
        title = (c.brand?.isNotEmpty ?? false) ? c.brand! : c.name;
        subtitle = 'loyaltyCardLabel'.tr();
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13 + 1 * prominence,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1 + 1 * prominence),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11 + 1 * prominence,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  String _maskedIban(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 8) return raw;
    final head = clean.substring(0, 4);
    final tail = clean.substring(clean.length - 4);
    return '$head •••• •••• •••• $tail';
  }
}

class _EmptyHint extends StatelessWidget {
  final HomeFilter filter;
  const _EmptyHint({required this.filter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = filter == HomeFilter.favorites
        ? 'noFavoritesYet'.tr()
        : 'walletAwaits'.tr();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpaceMd,
        vertical: kSpaceLg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filter == HomeFilter.favorites)
            Icon(
              Icons.star_outline_rounded,
              size: 28,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          if (filter == HomeFilter.favorites) const SizedBox(height: kSpaceXS),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
