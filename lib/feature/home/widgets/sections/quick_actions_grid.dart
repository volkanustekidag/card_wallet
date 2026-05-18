import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:share_plus/share_plus.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/utils/share_origin.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sheets/iban_picker_sheet.dart';

/// 2x2 action grid sitting between the action row and the filter chips.
/// Replaces the older 3-up rail. Each tile has a coloured icon plate, a
/// title and a subtitle so the actions are self-explanatory at a glance.
class QuickActionsGrid extends StatelessWidget {
  final HomeController controller;
  const QuickActionsGrid({Key? key, required this.controller})
      : super(key: key);

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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.add_rounded,
                  title: 'qaAddCard'.tr(),
                  subtitle: 'qaAddCardSub'.tr(),
                  accent: colorScheme.primary,
                  onTap: () => _pickAddTarget(context),
                ),
              ),
              const SizedBox(width: kSpaceMd),
              Expanded(
                child: _ActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'qaScanCard'.tr(),
                  subtitle: 'qaScanCardSub'.tr(),
                  accent: colorScheme.secondary,
                  onTap: () => _onScan(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpaceMd),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.send_rounded,
                  title: 'qaShareIban'.tr(),
                  subtitle: 'qaShareIbanSub'.tr(),
                  accent: colorScheme.tertiary,
                  onTap: () => _onShareIban(context),
                ),
              ),
              const SizedBox(width: kSpaceMd),
              Expanded(
                child: _ActionTile(
                  icon: Icons.style_rounded,
                  title: 'qaMyCards'.tr(),
                  subtitle: 'qaMyCardsSub'.tr(),
                  accent: const Color(0xFFE57373),
                  onTap: () => _onMyCards(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAddTarget(BuildContext context) =>
      showAddCardTypeSheet(context);

  void _onScan(BuildContext context) {
    HapticFeedback.lightImpact();
    Get.toNamed('/addCreditCard', arguments: {'autoScan': true})?.then((_) {
      controller.refreshData();
    });
  }

  Future<void> _onShareIban(BuildContext context) async {
    HapticFeedback.lightImpact();
    final ibans = controller.ibanCards.toList();
    if (ibans.isEmpty) {
      if (!context.mounted) return;
      context.showWarningSnackBar('shareIbanNoCard');
      return;
    }
    IbanCard? target;
    if (ibans.length == 1) {
      target = ibans.first;
    } else {
      target = await showIbanPickerSheet(context: context, ibans: ibans);
    }
    if (target == null) return;
    if (!context.mounted) return;
    final text =
        '${target.bankName}\nIBAN: ${target.iban}\n${target.cardHolder}';
    await Share.share(text, sharePositionOrigin: shareOriginFromContext(context));
  }

  void _onMyCards() {
    HapticFeedback.lightImpact();
    Get.toNamed('/allCards');
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  double _scale = 1;
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Offset? _burstOrigin;

  void _press(bool down) => setState(() => _scale = down ? 0.96 : 1);

  void _fireBurst(Offset local) {
    setState(() => _burstOrigin = local);
    _burst
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (d) {
        _press(true);
        _fireBurst(d.localPosition);
      },
      onTapCancel: () => _press(false),
      onTapUp: (_) => _press(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: kFastAnim,
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            kSpaceMd,
            kSpaceMd,
            kSpaceMd,
            kSpaceMd,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.04),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.accent, size: 22),
                  ),
                  const SizedBox(height: kSpaceMd),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (context, _) {
                      if (_burstOrigin == null || _burst.value == 0) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        painter: _TileBurstPainter(
                          origin: _burstOrigin!,
                          progress: _burst.value,
                          color: widget.accent,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileBurstPainter extends CustomPainter {
  final Offset origin;
  final double progress;
  final Color color;

  _TileBurstPainter({
    required this.origin,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress);
    final radius = 120 * t;
    final alpha = (1 - t) * 0.45;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1 - t * 0.6)
      ..color = color.withValues(alpha: alpha);
    canvas.drawCircle(origin, radius, paint);
    final fillPaint = Paint()
      ..color = color.withValues(alpha: alpha * 0.35);
    canvas.drawCircle(origin, radius * 0.92, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _TileBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.origin != origin;
}

