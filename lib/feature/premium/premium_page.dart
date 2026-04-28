import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  late final PremiumController _premiumController;
  late final PageController _featurePageController;
  Timer? _autoSlideTimer;
  Worker? _productWorker;
  int _currentFeatureIndex = 0;
  ProductDetails? _selectedProduct;

  static const _autoSlideInterval = Duration(seconds: 5);
  static const _autoSlideAnimation = Duration(milliseconds: 450);

  static const List<_FeatureCardData> _featureCards = [
    _FeatureCardData(
      icon: Icons.credit_card,
      titleKey: 'featureUnlimitedCardsTitle',
      descriptionKey: 'featureUnlimitedCardsDesc',
    ),
    _FeatureCardData(
      icon: Icons.document_scanner,
      titleKey: 'featureIbanScanTitle',
      descriptionKey: 'featureIbanScanDesc',
    ),
    _FeatureCardData(
      icon: Icons.qr_code,
      titleKey: 'featureQrCreateTitle',
      descriptionKey: 'featureQrCreateDesc',
    ),
    _FeatureCardData(
      icon: Icons.cloud_sync,
      titleKey: 'featureBackupRestoreTitle',
      descriptionKey: 'featureBackupRestoreDesc',
    ),
    _FeatureCardData(
      icon: Icons.fingerprint,
      titleKey: 'featureBiometricTitle',
      descriptionKey: 'featureBiometricDesc',
    ),
    _FeatureCardData(
      icon: Icons.block,
      titleKey: 'featureAdFreeTitle',
      descriptionKey: 'featureAdFreeDesc',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _premiumController = Get.find<PremiumController>();
    _featurePageController = PageController(viewportFraction: 0.86);
    _productWorker = ever<List<ProductDetails>>(
      _premiumController.availableProductsRx,
      (_) => _ensureDefaultSelectedProduct(),
    );
    _ensureDefaultSelectedProduct();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide());
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _featurePageController.dispose();
    _productWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'goPremium'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _handleRestore,
            child: Text(
              'restorePurchases'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Obx(() {
        final isLoading = _premiumController.isLoading;
        final monthly = _premiumController.monthlyProduct;
        final yearly = _premiumController.yearlyProduct;
        final lifetime = _premiumController.lifetimeProduct;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(colorScheme),
                  const SizedBox(height: 16),
                  _buildFeatureCarousel(colorScheme),
                  const SizedBox(height: 20),
                  _buildPricingSection(
                    colorScheme: colorScheme,
                    monthly: monthly,
                    yearly: yearly,
                    lifetime: lifetime,
                  ),
                  const SizedBox(height: 12),
                  _buildLegalLinks(colorScheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: colorScheme.surface.withValues(alpha: 0.65),
                  child: const Center(child: LoadingWidget()),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Header + carousel (unchanged from M1)
  // ---------------------------------------------------------------------------

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'premiumHeaderTitle'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'premiumHeaderSubtitle'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCarousel(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _featurePageController,
              clipBehavior: Clip.none,
              itemCount: _featureCards.length,
              onPageChanged: (index) {
                setState(() => _currentFeatureIndex = index);
              },
              itemBuilder: (context, index) {
                final feature = _featureCards[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildFeatureCard(feature, index, colorScheme),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildPageIndicator(colorScheme),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    _FeatureCardData feature,
    int index,
    ColorScheme colorScheme,
  ) {
    const gradients = [
      [Color(0xFF8B0000), Color(0xFFB71C1C)],
      [Color(0xFF9C1F27), Color(0xFFD33C2D)],
      [Color(0xFF8C1C3A), Color(0xFFCC5A2B)],
    ];
    final baseGradient = gradients[index % gradients.length];
    final gradientColors = [
      baseGradient[0],
      baseGradient[1],
      const Color(0xFFF2C94C),
    ];

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.65, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(feature.icon, color: Colors.white, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.titleKey.tr(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  feature.descriptionKey.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_featureCards.length, (index) {
        final isActive = index == _currentFeatureIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 18 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Pricing — 3 plan cards (monthly / yearly+free trial / lifetime)
  // ---------------------------------------------------------------------------

  Widget _buildPricingSection({
    required ColorScheme colorScheme,
    required ProductDetails? monthly,
    required ProductDetails? yearly,
    required ProductDetails? lifetime,
  }) {
    if (monthly == null && yearly == null && lifetime == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'premiumProductsUnavailable'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            color: colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'plansTitle'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        if (yearly != null) ...[
          _buildPlanCard(
            colorScheme: colorScheme,
            product: yearly,
            title: 'yearlyPlanTitle'.tr(),
            primaryPrice: yearly.price,
            cadence: 'perYear'.tr(),
            badge: 'planBestValue'.tr(),
            subtext: _buildMonthlyEquivalent(yearly),
            extraBadge: _buildFreeTrialBadge(yearly, colorScheme),
            savingsLabel: _savingsLabel(yearly: yearly, monthly: monthly),
          ),
          const SizedBox(height: 12),
        ],
        if (monthly != null) ...[
          _buildPlanCard(
            colorScheme: colorScheme,
            product: monthly,
            title: 'monthlyPlanTitle'.tr(),
            primaryPrice: monthly.price,
            cadence: 'perMonth'.tr(),
          ),
          const SizedBox(height: 12),
        ],
        if (lifetime != null) ...[
          _buildPlanCard(
            colorScheme: colorScheme,
            product: lifetime,
            title: 'lifetimePlanTitle'.tr(),
            primaryPrice: lifetime.price,
            cadence: 'oneTimePayment'.tr(),
            description: 'unlimitedAccess'.tr(),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        _buildPrimaryCta(colorScheme),
      ],
    );
  }

  Widget _buildPlanCard({
    required ColorScheme colorScheme,
    required ProductDetails product,
    required String title,
    required String primaryPrice,
    required String cadence,
    String? description,
    String? badge,
    String? subtext,
    Widget? extraBadge,
    String? savingsLabel,
  }) {
    final isSelected = _selectedProduct?.id == product.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.25),
          width: isSelected ? 1.4 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onPlanSelected(product),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (badge != null) _badge(colorScheme, badge),
                        if (extraBadge != null) extraBadge,
                        if (savingsLabel != null)
                          _badge(
                            colorScheme,
                            savingsLabel,
                            color: Colors.green,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: primaryPrice,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '  $cadence',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subtext != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtext,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check,
                        size: 18, color: colorScheme.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(ColorScheme colorScheme, String text, {Color? color}) {
    final accent = color ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }

  Widget? _buildFreeTrialBadge(ProductDetails product, ColorScheme colorScheme) {
    // The in_app_purchase plugin exposes intro offers via the native product
    // detail subclass. We only know there's a trial when the product comes
    // from the store with a discount/intro period; here we surface a static
    // localized badge if the yearly plan is configured for trial. The store
    // is the source of truth for availability.
    if (product.id == PremiumService.yearlyProductId) {
      return _badge(colorScheme, 'freeTrial3Days'.tr(), color: Colors.deepOrange);
    }
    return null;
  }

  String? _savingsLabel({
    required ProductDetails yearly,
    required ProductDetails? monthly,
  }) {
    if (monthly == null) return null;
    final monthlyAnnualised = monthly.rawPrice * 12;
    if (monthlyAnnualised <= 0 || yearly.rawPrice <= 0) return null;
    final ratio = (monthlyAnnualised - yearly.rawPrice) / monthlyAnnualised;
    if (ratio <= 0) return null;
    final percent = (ratio * 100).round();
    return 'savingsPercent'.tr(args: ['$percent']);
  }

  Widget _buildPrimaryCta(ColorScheme colorScheme) {
    final selected = _selectedProduct;
    final hasFreeTrial =
        selected != null && selected.id == PremiumService.yearlyProductId;
    final ctaText = selected == null
        ? 'continueWithSelectedPlan'.tr()
        : (hasFreeTrial
            ? 'startFreeTrial'.tr()
            : 'continueWithSelectedPlan'.tr());

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selected == null ? null : () => _handlePurchase(selected),
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
        child: Text(ctaText),
      ),
    );
  }

  Future<void> _handleRestore() async {
    await _premiumController.restorePurchases();
    if (!mounted) return;
    context.showInfoSnackBar('purchaseRestoreCompleted');
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    final success = await _premiumController.purchase(product);
    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      final messengerContext = Get.context ?? context;
      messengerContext.showSuccessSnackBar('premiumActivated');
    } else {
      HapticFeedback.heavyImpact();
      context.showErrorSnackBar('purchaseFailed');
    }
  }

  void _ensureDefaultSelectedProduct() {
    if (_selectedProduct != null) return;
    // Default to yearly (best value) when present.
    final candidate = _premiumController.yearlyProduct ??
        _premiumController.monthlyProduct ??
        _premiumController.lifetimeProduct;
    if (candidate != null && mounted) {
      setState(() => _selectedProduct = candidate);
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_featureCards.length < 2) return;

    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (_) {
      if (!_featurePageController.hasClients) return;
      final nextPage = (_currentFeatureIndex + 1) % _featureCards.length;
      _featurePageController.animateToPage(
        nextPage,
        duration: _autoSlideAnimation,
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPlanSelected(ProductDetails product) {
    if (_selectedProduct?.id == product.id) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedProduct = product);
  }

  String _buildMonthlyEquivalent(ProductDetails yearlyProduct) {
    final monthlyRaw = yearlyProduct.rawPrice / 12;
    final currencySymbol = _extractCurrencySymbol(yearlyProduct.price) ??
        yearlyProduct.currencyCode;
    final formatter =
        NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    return 'monthlyEquivalent'.tr(args: [formatter.format(monthlyRaw)]);
  }

  String? _extractCurrencySymbol(String price) {
    final trimmed = price.trim();
    final match = RegExp(r'[^\d\s.,]+').firstMatch(trimmed);
    return match?.group(0);
  }

  Widget _buildLegalLinks(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () =>
              _launchUrl('https://www.olkan.dev/terms/cardwallet'),
          child: Text(
            'termsOfUse'.tr(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '•',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        GestureDetector(
          onTap: () =>
              _launchUrl('https://www.olkan.dev/privacy/cardwallet'),
          child: Text(
            'privacyPolicy'.tr(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) context.showErrorSnackBar('couldNotLaunchUrl');
    }
  }
}

class _FeatureCardData {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  const _FeatureCardData({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}
