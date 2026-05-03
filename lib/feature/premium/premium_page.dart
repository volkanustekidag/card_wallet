import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/styles/app_themes.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';

/// Paywall built to convert: tight hero, a single hero featured plan
/// (yearly with prominent savings + free-trial badge), the alternates
/// tucked below, a compact feature checklist, and a bold gold CTA with
/// a glow + arrow. Underlying purchase / restore wiring is unchanged.
class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage>
    with TickerProviderStateMixin {
  late final PremiumController _premiumController;
  late final AnimationController _diamondController;
  late final AnimationController _ctaPulseController;
  Worker? _productWorker;
  ProductDetails? _selectedProduct;
  _PremiumFeatureSpec? _triggerFeature;

  // Each feature pairs a translation key with the icon that visually
  // represents it; `ad-free` was dropped because the app has no ads.
  static const List<_Feature> _features = [
    _Feature('featureUnlimitedCardsTitle', Icons.credit_card_rounded),
    _Feature('featureBackupRestoreTitle', Icons.cloud_sync_rounded),
    _Feature('featureBiometricTitle', Icons.fingerprint_rounded),
    _Feature('featureIbanScanTitle', Icons.document_scanner_rounded),
    _Feature('featureQrCreateTitle', Icons.qr_code_rounded),
  ];

  // Pass `arguments: {'feature': '<key>'}` when navigating to /premium to
  // surface a single feature card (instead of the wrap of all features).
  // The keys mirror the feature title keys without the title suffix.
  static const Map<String, _PremiumFeatureSpec> _featureSpecs = {
    'unlimitedCards': _PremiumFeatureSpec(
      'featureUnlimitedCardsTitle',
      'featureUnlimitedCardsDesc',
      Icons.credit_card_rounded,
    ),
    'backupRestore': _PremiumFeatureSpec(
      'featureBackupRestoreTitle',
      'featureBackupRestoreDesc',
      Icons.cloud_sync_rounded,
    ),
    'biometric': _PremiumFeatureSpec(
      'featureBiometricTitle',
      'featureBiometricDesc',
      Icons.fingerprint_rounded,
    ),
    'ibanScan': _PremiumFeatureSpec(
      'featureIbanScanTitle',
      'featureIbanScanDesc',
      Icons.document_scanner_rounded,
    ),
    'qrCreate': _PremiumFeatureSpec(
      'featureQrCreateTitle',
      'featureQrCreateDesc',
      Icons.qr_code_rounded,
    ),
  };

  @override
  void initState() {
    super.initState();
    _premiumController = Get.find<PremiumController>();
    final args = Get.arguments;
    if (args is Map && args['feature'] is String) {
      _triggerFeature = _featureSpecs[args['feature'] as String];
    }
    _diamondController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _ctaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _productWorker = ever<List<ProductDetails>>(
      _premiumController.availableProductsRx,
      (_) => _ensureDefaultSelectedProduct(),
    );
    _ensureDefaultSelectedProduct();
  }

  @override
  void dispose() {
    _diamondController.dispose();
    _ctaPulseController.dispose();
    _productWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme regardless of the app's theme setting — the
    // gold-on-white design was tuned for that palette and reads as
    // "premium" most clearly. Wrapping with Theme makes every Theme.of()
    // call inside the page return the light values.
    return Theme(
      data: AppThemes.lightTheme,
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Obx(() {
        final isLoading = _premiumController.isLoading;
        final monthly = _premiumController.monthlyProduct;
        final yearly = _premiumController.yearlyProduct;
        final lifetime = _premiumController.lifetimeProduct;

        // Order plans by display priority and tag the cheapest per-month
        // subscription with BEST VALUE — lifetime is excluded from that
        // comparison since it has no period to normalise to.
        final orderedPlans = <ProductDetails>[
          if (yearly != null) yearly,
          if (monthly != null) monthly,
          if (lifetime != null) lifetime,
        ];
        final bestValueId = _bestValueProductId(monthly, yearly);

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 380,
              child: _HeroBackdrop(isDark: isDark),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                  ),
                  _TopBar(
                    onClose: () => Get.back(),
                    onRestore: _handleRestore,
                  ),
                  _Hero(controller: _diamondController),
                  const SizedBox(height: 28),
                  if (_triggerFeature != null)
                    _BigFeatureCard(spec: _triggerFeature!)
                  else
                    _FeatureChecklist(features: _features),
                  const SizedBox(height: 28),
                  if (orderedPlans.isEmpty)
                    _ProductsUnavailable()
                  else
                    _PricingRow(
                      plans: orderedPlans,
                      monthlyId: monthly?.id,
                      yearlyId: yearly?.id,
                      lifetimeId: lifetime?.id,
                      bestValueId: bestValueId,
                      selected: _selectedProduct,
                      onSelected: _onPlanSelected,
                    ),
                  const SizedBox(height: 20),
                  _CtaButton(
                    product: _selectedProduct,
                    pulseController: _ctaPulseController,
                    onPressed: _selectedProduct == null
                        ? null
                        : () => _handlePurchase(_selectedProduct!),
                  ),
                  const SizedBox(height: 8),
                  _CtaSubText(product: _selectedProduct),
                  const SizedBox(height: 18),
                  _LegalLinks(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: colorScheme.surface.withValues(alpha: 0.65),
                  child: const Center(child: LoadingWidget()),
                ),
              ),
          ],
        );
      }),
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
      (Get.context ?? context).showSuccessSnackBar('premiumActivated');
    } else {
      HapticFeedback.heavyImpact();
      context.showErrorSnackBar('purchaseFailed');
    }
  }

  void _ensureDefaultSelectedProduct() {
    if (_selectedProduct != null) return;
    final candidate = _premiumController.yearlyProduct ??
        _premiumController.monthlyProduct ??
        _premiumController.lifetimeProduct;
    if (candidate != null && mounted) {
      setState(() => _selectedProduct = candidate);
    }
  }

  void _onPlanSelected(ProductDetails product) {
    if (_selectedProduct?.id == product.id) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedProduct = product);
  }

  /// The cheapest subscription on a per-month basis. Lifetime is excluded
  /// because it isn't a recurring plan; it gets its own ONE-TIME badge.
  ///
  /// The "monthly slot" can fall back to the legacy weekly product when
  /// the store hasn't been updated yet — converting weekly → per-month
  /// (×52/12 ≈ 4.33) is what made the yearly plan correctly win on the
  /// per-month comparison.
  String? _bestValueProductId(
    ProductDetails? monthly,
    ProductDetails? yearly,
  ) {
    final candidates = <String, double>{};
    if (yearly != null && yearly.rawPrice > 0) {
      candidates[yearly.id] = yearly.rawPrice / 12;
    }
    if (monthly != null && monthly.rawPrice > 0) {
      final isWeekly = monthly.id == PremiumService.weeklyProductId;
      candidates[monthly.id] =
          isWeekly ? monthly.rawPrice * (52 / 12) : monthly.rawPrice;
    }
    if (candidates.isEmpty) return null;
    final sorted = candidates.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.key;
  }
}

// ---------------------------------------------------------------------------
// Hero backdrop — deeper gold radial glow.
// ---------------------------------------------------------------------------

class _HeroBackdrop extends StatelessWidget {
  final bool isDark;
  const _HeroBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.0,
          colors: isDark
              ? [
                  const Color(0x77B8862C),
                  const Color(0x33B8862C),
                  Colors.transparent,
                ]
              : [
                  const Color(0x44E0B85F),
                  const Color(0x1FE0B85F),
                  Colors.transparent,
                ],
          stops: const [0, 0.55, 1],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar.
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onRestore;
  const _TopBar({required this.onClose, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onRestore,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            child: Text(
              'restorePurchases'.tr(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — diamond + PREMIUM eyebrow + big title.
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  final AnimationController controller;
  const _Hero({required this.controller});

  static const _gold = Color(0xFFC8A14A);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big bold title — typography-only, no sparkle. FittedBox keeps
          // long localisations (e.g. "Premium'a Geç") from overflowing on
          // narrow screens.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'premiumHeroTitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                height: 1.05,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // First sub: dark "Unlimited cards." + gold "More control."
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              children: [
                TextSpan(
                  text: 'premiumHeroSub'.tr(),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: 'premiumHeroSubAccent'.tr(),
                  style: const TextStyle(
                    color: _gold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Second sub: smaller muted tagline.
          Text(
            'premiumHeroTagline'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          const _HeroCardStack(),
        ],
      ),
    );
  }
}

// Three placeholder cards stacked: a big teal IBAN-style card in front,
// purple + rose cards peeking at slight angles behind. Pure decoration —
// sells the "your wallet, premium" feel without needing real data.
class _HeroCardStack extends StatelessWidget {
  const _HeroCardStack();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.62).clamp(220.0, 320.0);
    final cardHeight = cardWidth / 1.6;

    return SizedBox(
      height: cardHeight + 20,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Left peek — purple
          Transform.translate(
            offset: Offset(-cardWidth * 0.42, 8),
            child: Transform.rotate(
              angle: -0.10,
              child: Opacity(
                opacity: 0.55,
                child: _PlaceholderCard(
                  width: cardWidth,
                  height: cardHeight,
                  isIban: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB084CC), Color(0xFF7B5BA0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Right peek — rose
          Transform.translate(
            offset: Offset(cardWidth * 0.42, 8),
            child: Transform.rotate(
              angle: 0.10,
              child: Opacity(
                opacity: 0.55,
                child: _PlaceholderCard(
                  width: cardWidth,
                  height: cardHeight,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0A0A8), Color(0xFFC07480)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Center — teal, prominent
          _PlaceholderCard(
            width: cardWidth,
            height: cardHeight,
            isFront: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF2A7B6A), Color(0xFF1F5648)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final double width;
  final double height;
  final Gradient gradient;
  final bool isFront;
  final bool isIban;

  const _PlaceholderCard({
    required this.width,
    required this.height,
    required this.gradient,
    this.isFront = false,
    this.isIban = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFront
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AKBANK',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 26,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFEAC76C),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Spacer(),
            if (isIban)
              Text(
                'IBAN',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              'TR12 1234 •••• •••• 6543',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'VOLKAN USTEKIDAG',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '12345334',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Pricing — equal-design tiles in a horizontal row. BEST VALUE badge is
// applied programmatically to whichever subscription has the lowest cost
// per month; lifetime gets the ONE-TIME badge regardless. No featured
// gradient card, no asymmetry — every plan is shown side-by-side so the
// comparison is honest.
// ---------------------------------------------------------------------------

class _PricingRow extends StatelessWidget {
  final List<ProductDetails> plans;
  final String? monthlyId;
  final String? yearlyId;
  final String? lifetimeId;
  final String? bestValueId;
  final ProductDetails? selected;
  final ValueChanged<ProductDetails> onSelected;

  const _PricingRow({
    required this.plans,
    required this.monthlyId,
    required this.yearlyId,
    required this.lifetimeId,
    required this.bestValueId,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Top padding leaves room for the BEST VALUE / ONE-TIME pill that
      // floats half-above the card border.
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < plans.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PlanTile(
                  product: plans[i],
                  isSelected: selected?.id == plans[i].id,
                  isBestValue: plans[i].id == bestValueId,
                  isLifetime: plans[i].id == lifetimeId,
                  isYearly: plans[i].id == yearlyId,
                  monthlyEquivalent: plans[i].id == yearlyId
                      ? _monthlyEquivalent(plans[i])
                      : null,
                  onTap: () => onSelected(plans[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthlyEquivalent(ProductDetails yearlyProduct) {
    final monthlyRaw = yearlyProduct.rawPrice / 12;
    if (monthlyRaw <= 0) return '';
    final symbol =
        _extractSymbol(yearlyProduct.price) ?? yearlyProduct.currencyCode;
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2)
        .format(monthlyRaw);
  }

  String? _extractSymbol(String price) {
    final match = RegExp(r'[^\d\s.,]+').firstMatch(price.trim());
    return match?.group(0);
  }
}

class _PlanTile extends StatefulWidget {
  final ProductDetails product;
  final bool isSelected;
  final bool isBestValue;
  final bool isLifetime;
  final bool isYearly;
  final String? monthlyEquivalent;
  final VoidCallback onTap;

  const _PlanTile({
    required this.product,
    required this.isSelected,
    required this.isBestValue,
    required this.isLifetime,
    required this.isYearly,
    required this.monthlyEquivalent,
    required this.onTap,
  });

  @override
  State<_PlanTile> createState() => _PlanTileState();
}

class _PlanTileState extends State<_PlanTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmer;

  static const _gold = Color(0xFFC8A14A);
  static const _goldGradient = LinearGradient(
    colors: [Color(0xFFE0B85F), Color(0xFFB8862C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isBestValue) _ensureShimmer();
  }

  @override
  void didUpdateWidget(covariant _PlanTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBestValue) {
      _ensureShimmer();
    } else if (_shimmer != null) {
      _shimmer!.dispose();
      _shimmer = null;
    }
  }

  void _ensureShimmer() {
    _shimmer ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showTopBadge = widget.isBestValue || widget.isLifetime;
    final topBadgeText = widget.isBestValue
        ? 'premiumPlanBest'.tr()
        : (widget.isLifetime ? 'premiumPlanOneTime'.tr() : '');
    final borderColor = widget.isSelected
        ? _gold
        : colorScheme.onSurface.withValues(alpha: 0.10);

    // The card itself fills the row's stretched height (Row + IntrinsicHeight
    // in the parent), so all tiles share the same top AND bottom edge. The
    // inner Stack with StackFit.expand makes the content area receive the
    // full card height, while the Column inside (mainAxisSize.min) keeps
    // the text content top-aligned regardless of the extra "/ month" line
    // on the yearly tile. The badge is in the same Stack with a negative
    // top, so it bleeds above the card border without taking room inside.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: widget.isSelected ? 1.6 : 1,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _planTitle().toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.product.price,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: colorScheme.onSurface,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cadenceLabel(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    if (widget.monthlyEquivalent != null &&
                        widget.monthlyEquivalent!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'premiumPerMonthEq'
                            .tr(args: [widget.monthlyEquivalent!]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Sheen sweep over the BEST VALUE tile. Clipped to the card's
              // rounded rect, sat under the floating badge so the badge
              // never gets washed out by the highlight.
              if (widget.isBestValue && _shimmer != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedBuilder(
                        animation: _shimmer!,
                        builder: (_, __) => CustomPaint(
                          painter: _ShimmerPainter(
                            progress: _shimmer!.value,
                            widthFactor: 0.45,
                            maxAlpha: 0.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (showTopBadge)
                Positioned(
                  top: -10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: widget.isBestValue ? _goldGradient : null,
                        color: widget.isBestValue
                            ? null
                            : colorScheme.onSurface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: widget.isBestValue
                            ? [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        topBadgeText,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: widget.isBestValue
                              ? Colors.white
                              : colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _planTitle() {
    if (widget.isYearly) return 'yearlyPlanTitle'.tr();
    if (widget.isLifetime) return 'lifetimePlanTitle'.tr();
    if (widget.product.id == PremiumService.weeklyProductId) {
      return 'weeklyPlanTitle'.tr();
    }
    return 'monthlyPlanTitle'.tr();
  }

  String _cadenceLabel() {
    if (widget.isYearly) return 'perYear'.tr();
    if (widget.isLifetime) return 'oneTimePayment'.tr();
    if (widget.product.id == PremiumService.weeklyProductId) {
      return 'perWeek'.tr();
    }
    return 'perMonth'.tr();
  }
}

class _ProductsUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'premiumProductsUnavailable'.tr(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature checklist — single-line items, each with a soft gold-tinted icon
// plate matching the feature it describes (no generic checkmarks).
// ---------------------------------------------------------------------------

class _Feature {
  final String titleKey;
  final IconData icon;
  const _Feature(this.titleKey, this.icon);
}

/// Spec used when the paywall is opened with a specific feature trigger
/// (`Get.toNamed('/premium', arguments: {'feature': 'biometric'})`).
/// Pairs a title + description + icon so the page can render a single
/// hero feature card instead of the wrap of all features.
class _PremiumFeatureSpec {
  final String titleKey;
  final String descKey;
  final IconData icon;
  const _PremiumFeatureSpec(this.titleKey, this.descKey, this.icon);
}

/// Minimal "the feature you tried to use" highlight. No card box, no
/// dark fill — just a gold icon plate, the title and a short description
/// centred on the page. A periodic shine sweeps over the icon to give
/// the moment a hint of motion without feeling like a banner ad.
class _BigFeatureCard extends StatefulWidget {
  final _PremiumFeatureSpec spec;
  const _BigFeatureCard({required this.spec});

  @override
  State<_BigFeatureCard> createState() => _BigFeatureCardState();
}

class _BigFeatureCardState extends State<_BigFeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  static const _gold = Color(0xFFC8A14A);
  static const _goldGradient = LinearGradient(
    colors: [Color(0xFFE0B85F), Color(0xFFB8862C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _goldGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.spec.icon, color: Colors.white, size: 24),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (_, __) => CustomPaint(
                        painter: _ShimmerPainter(progress: _shimmer.value),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.spec.titleKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              height: 1.15,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.spec.descKey.tr(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal white sweep that travels from off-screen-left to off-screen-
/// right during the first ~35 % of the cycle, then idles so the card
/// doesn't strobe.
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final double widthFactor;
  final double maxAlpha;
  const _ShimmerPainter({
    required this.progress,
    this.widthFactor = 0.32,
    this.maxAlpha = 0.22,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.35) return;
    final t = progress / 0.35;
    final shineWidth = size.width * widthFactor;
    final dx = -shineWidth + (size.width + shineWidth * 2) * t;

    final rect = Rect.fromLTWH(
      dx,
      -size.height * 0.2,
      shineWidth,
      size.height * 1.4,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: maxAlpha),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(rect);

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.35);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.widthFactor != widthFactor ||
      oldDelegate.maxAlpha != maxAlpha;
}

class _FeatureChecklist extends StatelessWidget {
  final List<_Feature> features;
  const _FeatureChecklist({required this.features});

  static const _gold = Color(0xFFC8A14A);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final f in features)
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.icon, size: 14, color: _gold),
                  const SizedBox(width: 6),
                  Text(
                    f.titleKey.tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA — bigger, bolder, with subtle pulse and arrow.
// ---------------------------------------------------------------------------

class _CtaButton extends StatelessWidget {
  final ProductDetails? product;
  final AnimationController pulseController;
  final VoidCallback? onPressed;

  const _CtaButton({
    required this.product,
    required this.pulseController,
    this.onPressed,
  });

  static const _gold = Color(0xFFC8A14A);
  static const _goldGradient = LinearGradient(
    colors: [Color(0xFFE0B85F), Color(0xFFB8862C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    // Free trial is store-side configuration, not something to assume from
    // a product ID — the wallet's products don't ship with one yet, so the
    // CTA stays neutral.
    final label = 'getPremium'.tr();

    final disabled = onPressed == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) {
            final t = pulseController.value;
            final glowAlpha = 0.35 + 0.25 * (0.5 - (t - 0.5).abs()) * 2;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: onPressed,
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: _goldGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: disabled
                        ? null
                        : [
                            BoxShadow(
                              color: _gold.withValues(alpha: glowAlpha),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CtaSubText extends StatelessWidget {
  final ProductDetails? product;
  const _CtaSubText({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      'premiumCancelAnytime'.tr(),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer.
// ---------------------------------------------------------------------------

class _LegalLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegalLink(
          label: 'termsOfUse'.tr(),
          url: 'https://www.olkan.dev/terms/cardwallet',
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '·',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        _LegalLink(
          label: 'privacyPolicy'.tr(),
          url: 'https://www.olkan.dev/privacy/cardwallet',
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;
  final Color color;
  const _LegalLink({
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launch(context, url),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) context.showErrorSnackBar('couldNotLaunchUrl');
    }
  }
}
