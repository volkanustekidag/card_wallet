import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Obx(() {
          if (_premiumController.isLoading) {
            return const LoadingWidget();
          }

          final weeklyProduct = _premiumController.weeklyProduct;
          final yearlyProduct = _premiumController.yearlyProduct;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Get.back(),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Unlock unlimited cards',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Remove ads and save unlimited credit & IBAN cards.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 3.h),
                _buildBenefitsList(colorScheme),
                SizedBox(height: 3.h),
                if (yearlyProduct != null)
                  _buildYearlyPlan(colorScheme)
                else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    child: Text(
                      'premiumProductsUnavailable'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(height: 2.h),
                _buildPrimaryCta(yearlyProduct, colorScheme),
                SizedBox(height: 1.h),
                _buildTrustText(colorScheme),
                SizedBox(height: 3.h),
                if (weeklyProduct != null)
                  _buildWeeklyPlan(colorScheme, weeklyProduct),
                SizedBox(height: 4.h),
                _buildRestoreButton(colorScheme),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBenefitsList(ColorScheme colorScheme) {
    const benefits = [
      'Unlimited credit cards',
      'Unlimited IBAN cards',
      'Ad-free experience',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: benefits
            .map((benefit) => _buildFeatureItem(benefit, colorScheme))
            .toList(),
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
              style: TextStyle(
                fontFamily: 'Poppins',
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

  Widget _buildYearlyPlan(ColorScheme colorScheme) {
    final yearlyProduct = _premiumController.yearlyProduct;
    if (yearlyProduct == null) return const SizedBox.shrink();

    // Calculate monthly price
    final yearlyPriceValue = double.tryParse(
          yearlyProduct.price.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.'),
        ) ??
        0;
    final monthlyPrice = yearlyPriceValue / 12;
    final currencySymbol = yearlyProduct.price.contains('₺') ? '₺' : '\$';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 12),
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
                  'Yearly plan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Best value',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${yearlyProduct.price} / year',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Only $currencySymbol${monthlyPrice.toStringAsFixed(2)} per month',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta(
    ProductDetails? yearlyProduct,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: yearlyProduct == null
            ? null
            : () => _handlePurchase(yearlyProduct),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Upgrade to Premium'),
      ),
    );
  }

  Widget _buildTrustText(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cancel anytime.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Secure payment via Google Play / App Store.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyPlan(
    ColorScheme colorScheme,
    ProductDetails weeklyProduct,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly plan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${weeklyProduct.price} / week',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handlePurchase(weeklyProduct),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Try weekly'),
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
        'Restore purchases',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
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
