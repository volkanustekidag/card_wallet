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

  const EmptyListInfo({
    Key? key,
    this.ctaRoute,
    this.ctaLabel,
    this.ctaIcon = Icons.add_card,
    this.onCtaTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCta = (ctaRoute != null && ctaRoute!.isNotEmpty) || onCtaTap != null;
    final size = MediaQuery.of(context).size;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/svg/bank.svg",
              colorFilter: ColorFilter.mode(
                colorScheme.onSurface.withValues(alpha: 0.6),
                BlendMode.srcIn,
              ),
              width: size.width * 0.22,
            ),
            const SizedBox(height: 16),
            Text(
              "emptyList".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasCta) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (onCtaTap != null) {
                    onCtaTap!();
                  } else if (ctaRoute != null) {
                    Get.toNamed(ctaRoute!);
                  }
                },
                icon: Icon(ctaIcon, size: 18),
                label: Text(
                  (ctaLabel ?? 'addFirstCard').tr(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
