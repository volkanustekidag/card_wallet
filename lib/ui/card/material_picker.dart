import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/utils/premium_gate.dart';
import 'package:wallet_app/ui/card/card_face.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Horizontal row of card materials. The free ones come first; premium
/// ones carry a small gem and open the `premiumColors` paywall for free
/// users (same gate as before). An optional brand colour leads the row.
class MaterialPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  /// ARGB brand colour, shown first when set.
  final int? brandColor;
  final bool brandSelected;
  final VoidCallback? onBrand;

  const MaterialPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.brandColor,
    this.brandSelected = false,
    this.onBrand,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Row(
      children: [
        Text('cwMaterial'.tr(),
            style: CwType.footnote
                .copyWith(color: c.mute, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 40,
            child: _PremiumAware(builder: (premium) {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (brandColor != null)
                    _Swatch(
                      material: CardMaterial.brand(Color(brandColor!)),
                      selected: brandSelected,
                      onTap: onBrand,
                    ),
                  for (var i = 0; i < CardMaterial.count; i++)
                    _Swatch(
                      material: CardMaterial.of(i),
                      selected: !brandSelected && i == selected,
                      locked: !premium && CardMaterial.isPremium(i),
                      onTap: () {
                        if (!premium && CardMaterial.isPremium(i)) {
                          openPremiumGate('premiumColors');
                          return;
                        }
                        HapticFeedback.selectionClick();
                        onSelected(i);
                      },
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Rebuilds on premium changes when the controller exists (it always does
/// in the app; tests and previews may not register it).
class _PremiumAware extends StatelessWidget {
  final Widget Function(bool premium) builder;
  const _PremiumAware({required this.builder});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PremiumController>()) return builder(false);
    final p = Get.find<PremiumController>();
    return Obx(() => builder(p.isPremium));
  }
}

class _Swatch extends StatelessWidget {
  final CardMaterial material;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  const _Swatch({
    required this.material,
    required this.selected,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: CwMotion.fast,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? c.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CardFace(
                material: material,
                width: 48,
                height: 32,
                radius: 7,
                shadow: false,
                padding: EdgeInsets.zero,
              ),
              if (locked)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      boxShadow: CwElevation.e1(context),
                    ),
                    alignment: Alignment.center,
                    child: CwIcon(CwIcons.gem, size: 10, color: c.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
