import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans;

class EmptyListInfo extends StatelessWidget {
  /// Optional CTA: a route to navigate to and the label to show.
  /// When both are provided, a prominent button is rendered under the message.
  final String? ctaRoute;
  final String? ctaLabel;
  final IconData ctaIcon;
  final VoidCallback? onCtaTap;

  /// Optional override for the title key. Defaults to `emptyList`.
  final String titleKey;

  /// Optional secondary line under the title — e.g. a hint about what to do.
  final String? subtitleKey;

  /// Optional Material icon to render inside the glow disc instead of the
  /// default bank illustration. Use for search/filter-empty states.
  final IconData? icon;

  const EmptyListInfo({
    Key? key,
    this.ctaRoute,
    this.ctaLabel,
    this.ctaIcon = Icons.add_card,
    this.onCtaTap,
    this.titleKey = 'emptyList',
    this.subtitleKey,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCta =
        (ctaRoute != null && ctaRoute!.isNotEmpty) || onCtaTap != null;
    final accent = colorScheme.primary;

    final iconTint = accent.withValues(alpha: 0.7);

    return Center(
      child: Opacity(
        opacity: 0.75,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlowDisc(
                accent: accent,
                child: icon != null
                    ? Icon(icon, size: 36, color: iconTint)
                    : SvgPicture.asset(
                        'assets/svg/bank.svg',
                        colorFilter:
                            ColorFilter.mode(iconTint, BlendMode.srcIn),
                        width: 40,
                      ),
              ),
              const SizedBox(height: 18),
              Text(
                titleKey.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                  letterSpacing: -0.1,
                ),
              ),
              if (subtitleKey != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitleKey!.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ],
              if (hasCta) ...[
                const SizedBox(height: 20),
                _GradientCta(
                  label: (ctaLabel ?? 'addFirstCard').tr(),
                  icon: ctaIcon,
                  onTap: () {
                    if (onCtaTap != null) {
                      onCtaTap!();
                    } else if (ctaRoute != null) {
                      Get.toNamed(ctaRoute!);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat primary-color pill CTA. White text is hard-coded — the dark
/// scheme's `onPrimary` is dark slate, which would fail contrast against
/// the bright primary blue.
class _GradientCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft accent radial-glow disc, used as a backdrop for the empty-state
/// icon/illustration. Matches the icon treatment in the onboarding and
/// auth screens so empty states read as part of the same visual family.
class _GlowDisc extends StatelessWidget {
  final Color accent;
  final Widget child;
  const _GlowDisc({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
