import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';

/// All / Favorites / Credit / IBAN / Loyalty pills. Drives the
/// recent-cards list below. Selected chip uses an inverted dark fill so it
/// reads against the surface, matching the reference mock. The Favorites
/// chip is placed right after All so it stays close to the most-used
/// filter and doesn't get scrolled off small screens.
///
/// Reverse-parallax: when [scrollOffset] crosses [kBottomFocusStart] the
/// chips inflate (padding, font, icon) so the section feels promoted as
/// the user reaches it. Mirror to the wallet title's collapse on scroll.
class CardFilterChips extends StatelessWidget {
  final HomeFilter selected;
  final ValueChanged<HomeFilter> onChanged;
  final ValueNotifier<double>? scrollOffset;

  const CardFilterChips({
    Key? key,
    required this.selected,
    required this.onChanged,
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
    final hPad = kSpaceMd + 2 + 4 * prominence;
    final vPad = 8 + 2 * prominence;
    final fontSize = 12 + 1 * prominence;
    final iconSize = 14 + 2 * prominence;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        kSpaceMd + kSpaceXS * prominence,
        0,
        kSpaceMd + kSpaceXS * prominence,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: kSpaceLg,
                vertical: kSpaceSm,
              ),
              child: Row(
                children: [
                  _Chip(
                    label: 'filterAll'.tr(),
                    selected: selected == HomeFilter.all,
                    onTap: () => _select(HomeFilter.all),
                    horizontalPadding: hPad,
                    verticalPadding: vPad,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                  const SizedBox(width: kSpaceSm),
                  _Chip(
                    label: 'filterFavorites'.tr(),
                    leading: Icons.star_rounded,
                    leadingColor: const Color(0xFFFFB800),
                    selected: selected == HomeFilter.favorites,
                    onTap: () => _select(HomeFilter.favorites),
                    horizontalPadding: hPad,
                    verticalPadding: vPad,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                  const SizedBox(width: kSpaceSm),
                  _Chip(
                    label: 'filterCredit'.tr(),
                    selected: selected == HomeFilter.credit,
                    onTap: () => _select(HomeFilter.credit),
                    horizontalPadding: hPad,
                    verticalPadding: vPad,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                  const SizedBox(width: kSpaceSm),
                  _Chip(
                    label: 'filterIban'.tr(),
                    selected: selected == HomeFilter.iban,
                    onTap: () => _select(HomeFilter.iban),
                    horizontalPadding: hPad,
                    verticalPadding: vPad,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                  const SizedBox(width: kSpaceSm),
                  _Chip(
                    label: 'filterLoyalty'.tr(),
                    selected: selected == HomeFilter.loyalty,
                    onTap: () => _select(HomeFilter.loyalty),
                    horizontalPadding: hPad,
                    verticalPadding: vPad,
                    fontSize: fontSize,
                    iconSize: iconSize,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _select(HomeFilter filter) {
    HapticFeedback.selectionClick();
    onChanged(filter);
  }
}

class _Chip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leading;
  final Color? leadingColor;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double iconSize;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.leadingColor,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.fontSize,
    required this.iconSize,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(covariant _Chip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _pulse
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bg = widget.selected
        ? colorScheme.inverseSurface
        : colorScheme.surfaceContainerHighest;
    final fg = widget.selected
        ? colorScheme.onInverseSurface
        : colorScheme.onSurface.withValues(alpha: 0.78);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // elasticOut overshoots and settles — gives a magnetic snap
            // when a chip becomes selected. The pulse decays as v → 1.
            final v = _pulse.value;
            final eased = Curves.elasticOut.transform(v.clamp(0.0, 1.0));
            final pulseScale =
                widget.selected ? 1.0 + 0.06 * (1 - v) * eased : 1.0;
            return Transform.scale(scale: pulseScale, child: child);
          },
          child: AnimatedContainer(
            duration: kMediumAnim,
            curve: kHomeCurve,
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding,
              vertical: widget.verticalPadding,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: bg.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leading != null) ...[
                  Icon(
                    widget.leading,
                    size: widget.iconSize,
                    color: widget.selected
                        ? fg
                        : (widget.leadingColor ?? fg),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    color: fg,
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
