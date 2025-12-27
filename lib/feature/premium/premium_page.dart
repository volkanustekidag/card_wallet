import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';

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

                // Subscription plans
                _buildPlanOptions(colorScheme),

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

  Widget _buildPlanOptions(ColorScheme colorScheme) {
    final plans = <Widget>[];
    final weeklyProduct = _premiumController.weeklyProduct;
    final yearlyProduct = _premiumController.yearlyProduct;

    if (weeklyProduct != null) {
      plans.add(
        _buildPlanCard(
          colorScheme: colorScheme,
          product: weeklyProduct,
          title: 'weeklyPlanTitle'.tr(),
          description: 'weeklyPlanDescription'.tr(),
        ),
      );
    }

    if (yearlyProduct != null) {
      plans.add(
        _buildPlanCard(
          colorScheme: colorScheme,
          product: yearlyProduct,
          title: 'yearlyPlanTitle'.tr(),
          description: 'yearlyPlanDescription'.tr(),
          highlight: true,
        ),
      );
    }

    if (plans.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Text(
          'premiumProductsUnavailable'.tr(),
          style: GoogleFonts.poppins(
            color: colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: [
        ...plans,
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildPlanCard({
    required ColorScheme colorScheme,
    required ProductDetails product,
    required String title,
    required String description,
    bool highlight = false,
  }) {
    final backgroundColor = highlight
        ? colorScheme.primary.withOpacity(0.12)
        : colorScheme.surface;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (highlight)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'planBestValue'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                product.price,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _handlePurchase(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'choosePlan'.tr(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    final success = await _premiumController.purchase(product);
    if (!mounted) return;

    if (success) {
      Get.back();
      final messengerContext = Get.context ?? context;
      messengerContext.showSuccessSnackBar('premiumActivated');
    } else {
      context.showErrorSnackBar('purchaseFailed');
    }
  }
}
