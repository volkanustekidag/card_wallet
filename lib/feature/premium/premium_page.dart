import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  late final PremiumController _premiumController;

  @override
  void initState() {
    super.initState();
    _premiumController = Get.find<PremiumController>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'premium'.tr(),
          style: GoogleFonts.poppins(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        if (_premiumController.isLoading) {
          return const LoadingWidget();
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium Icon
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: 15.w,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),

                // Title
                Text(
                  'upgradeToPremium'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),

                // Description
                Text(
                  'premiumDescription'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),

                // Features List
                _buildFeaturesList(colorScheme),
                SizedBox(height: 4.h),

                // Purchase Button
                if (_premiumController.premiumProduct != null)
                  _buildPurchaseButton(colorScheme),

                SizedBox(height: 2.h),

                // Restore Purchases Button
                _buildRestoreButton(colorScheme),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturesList(ColorScheme colorScheme) {
    final features = [
      'unlimitedCreditCards'.tr(),
      'unlimitedIbanCards'.tr(),
      'adFreeExperience'.tr(),
      'premiumSupport'.tr(),
      'futurePremiumFeatures'.tr(),
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: features.map((feature) => _buildFeatureItem(feature, colorScheme)).toList(),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              feature,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(ColorScheme colorScheme) {
    final product = _premiumController.premiumProduct!;
    
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          final success = await _premiumController.purchasePremium();
          if (success) {
            // Sadece başarılı olursa sayfadan çık
            Get.back();
            context.showSuccessSnackBar('premiumActivated');
          } else {
            // Başarısız olursa sayfada kal ve hata göster
            context.showErrorSnackBar('purchaseFailed');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.amber.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, size: 24),
            const SizedBox(width: 12),
            Text(
              '${'getPremium'.tr()} - ${product.price}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreButton(ColorScheme colorScheme) {
    return TextButton(
      onPressed: () async {
        await _premiumController.restorePurchases();
        context.showInfoSnackBar('purchaseRestoreCompleted');
      },
      child: Text(
        'restorePurchases'.tr(),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}