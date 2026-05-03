import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Top-of-page header. Calm "Wallet" title on the left; on the right an add
/// button that opens a kind picker, and a settings cog. The cog is the only
/// settings entry point now that the bottom nav is gone, so removing it
/// would orphan PIN/theme/language/premium/backup screens.
///
/// Reacts to [scrollOffset]: title shrinks 22 → 18 px and softens slightly
/// while the user scrolls. Long-press on the add button opens a radial mini
/// menu instead of the full sheet.
class HomeHeader extends StatelessWidget {
  final HomeController controller;
  final ValueNotifier<double>? scrollOffset;
  const HomeHeader({
    Key? key,
    required this.controller,
    this.scrollOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLg,
        kSpaceSm,
        kSpaceLg,
        kSpaceSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _CollapsingTitle(
              text: 'wallet'.tr(),
              color: colorScheme.onSurface,
              scrollOffset: scrollOffset,
            ),
          ),
          _AddButton(),
          const SizedBox(width: kSpaceSm),
          _SettingsButton(controller: controller),
        ],
      ),
    );
  }
}

class _CollapsingTitle extends StatelessWidget {
  final String text;
  final Color color;
  final ValueNotifier<double>? scrollOffset;

  const _CollapsingTitle({
    required this.text,
    required this.color,
    this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    if (scrollOffset == null) return _styled(text, 22, 1.0);
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset!,
      builder: (context, value, _) {
        // 0 → 0 collapse, 80 → fully collapsed.
        final t = (value / 80.0).clamp(0.0, 1.0);
        final size = 24 - 4 * t;
        final opacity = 1.0 - 0.15 * t;
        return _styled(text, size, opacity);
      },
    );
  }

  Widget _styled(String value, double fontSize, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _pickAddTarget(context),
        onLongPress: () => _openRadial(context),
        child: Container(
          key: _buttonKey,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.add_rounded,
            size: 22,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Future<void> _openRadial(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final origin = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    if (!context.mounted) return;
    final type = await showGeneralDialog<CardLimitType>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      barrierLabel: 'addCard',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => _RadialAddMenu(origin: origin),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    );
    if (type != null && context.mounted) {
      await goToAddCard(context: context, type: type);
    }
  }

  Future<void> _pickAddTarget(BuildContext context) async {
    HapticFeedback.lightImpact();
    final colorScheme = Theme.of(context).colorScheme;
    final type = await showModalBottomSheet<CardLimitType>(
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
                _AddSheetTile(
                  icon: Icons.credit_card_rounded,
                  label: 'addCC'.tr(),
                  accent: colorScheme.primary,
                  onTap: () =>
                      Navigator.pop(sheetContext, CardLimitType.credit),
                ),
                _AddSheetTile(
                  icon: Icons.account_balance_rounded,
                  label: 'addIC'.tr(),
                  accent: colorScheme.secondary,
                  onTap: () => Navigator.pop(sheetContext, CardLimitType.iban),
                ),
                _AddSheetTile(
                  icon: Icons.local_offer_rounded,
                  label: 'addLC'.tr(),
                  accent: colorScheme.tertiary,
                  onTap: () =>
                      Navigator.pop(sheetContext, CardLimitType.loyalty),
                ),
                const SizedBox(height: kSpaceSm),
              ],
            ),
          ),
        );
      },
    );
    if (type != null && context.mounted) {
      await goToAddCard(context: context, type: type);
    }
  }
}

/// Three-icon radial menu anchored at [origin]. Icons fan out below the
/// button along an arc, each one staggered ~50ms behind the previous so
/// the open/close animation reads as a "spread".
class _RadialAddMenu extends StatefulWidget {
  final Offset origin;
  const _RadialAddMenu({required this.origin});

  @override
  State<_RadialAddMenu> createState() => _RadialAddMenuState();
}

class _RadialAddMenuState extends State<_RadialAddMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    // Arc fans down-left so it doesn't run off-screen on the right edge.
    final entries = <_RadialEntry>[
      _RadialEntry(
        icon: Icons.credit_card_rounded,
        label: 'addCC'.tr(),
        accent: colorScheme.primary,
        type: CardLimitType.credit,
        angle: math.pi * 0.62, // ~112°
      ),
      _RadialEntry(
        icon: Icons.account_balance_rounded,
        label: 'addIC'.tr(),
        accent: colorScheme.secondary,
        type: CardLimitType.iban,
        angle: math.pi * 0.78, // ~140°
      ),
      _RadialEntry(
        icon: Icons.local_offer_rounded,
        label: 'addLC'.tr(),
        accent: colorScheme.tertiary,
        type: CardLimitType.loyalty,
        angle: math.pi * 0.94, // ~169°
      ),
    ];
    const double radius = 110;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            for (var i = 0; i < entries.length; i++)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final start = i * 0.12;
                  final raw = ((_controller.value - start) / (1 - start))
                      .clamp(0.0, 1.0);
                  final t = Curves.easeOutBack.transform(raw);
                  final entry = entries[i];
                  final dx = math.cos(entry.angle) * radius * t;
                  final dy = math.sin(entry.angle) * radius * t;
                  return Positioned(
                    left: widget.origin.dx + dx - 28,
                    top: widget.origin.dy + dy - 28,
                    child: Opacity(
                      opacity: raw,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * raw,
                        child: _RadialIcon(entry: entry),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RadialEntry {
  final IconData icon;
  final String label;
  final Color accent;
  final CardLimitType type;
  final double angle;

  _RadialEntry({
    required this.icon,
    required this.label,
    required this.accent,
    required this.type,
    required this.angle,
  });
}

class _RadialIcon extends StatelessWidget {
  final _RadialEntry entry;
  const _RadialIcon({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop(entry.type);
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: entry.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: entry.accent.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(entry.icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final HomeController controller;
  const _SettingsButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          Get.toNamed('/settings')?.then((_) => controller.refreshData());
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.settings_rounded,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _AddSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _AddSheetTile({
    required this.icon,
    required this.label,
    required this.accent,
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
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 22),
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
