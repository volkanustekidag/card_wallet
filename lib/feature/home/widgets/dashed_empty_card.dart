import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/core/data/services/admob_service.dart';

class DashedEmptyCard extends StatelessWidget {
  final String route;
  final String text;

  const DashedEmptyCard({
    Key? key,
    required this.route,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 38),
      child: GestureDetector(
        onTap: () async {
          await AdMobService.showInterstitialAd();
          Get.toNamed(route)?.then(
            (value) => Get.find<HomeController>().refreshData(),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: DottedBorder(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            borderType: BorderType.RRect,
            strokeWidth: 2,
            dashPattern: const [12, 6],
            radius: const Radius.circular(16),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to add your first card',
                    style: GoogleFonts.poppins(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
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
