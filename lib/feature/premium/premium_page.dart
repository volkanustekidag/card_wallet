import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/constants/legal_urls.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/utils/locale_format.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/ui/card/card_face.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Paywall v2: the user's own cards fanned out on a night stage, one line
/// on why it opened (trigger), what Premium adds, the store's three plans
/// (yearly default + best-value badge + per-month equivalent) and one CTA.
/// Pricing, plans and gating are unchanged — this is presentation only.
class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  late final PremiumController _premiumController;
  Worker? _productWorker;
  ProductDetails? _selectedProduct;

  /// Premium subscribers see a status card instead of the plan picker; this
  /// flips to the picker when they tap "Change plan".
  bool _changingPlan = false;

  // For paywall_dismissed: how the user got here and whether they bought.
  String? _trigger;
  String? _featureArg;
  bool _purchased = false;

  /// Subtitle under the headline: why the paywall opened.
  static const Map<String, String> _triggerSubtitles = {
    'unlimitedCards': 'cwPaySubCards',
    'backupRestore': 'cwPaySubBackup',
    'walletExport': 'cwPaySubWallet',
    'qrCreate': 'cwPaySubQr',
    'premiumColors': 'cwPaySubColors',
  };

  @override
  void initState() {
    super.initState();
    _premiumController = Get.find<PremiumController>();
    final args = Get.arguments;
    String? triggerArg;
    String? featureArg;
    String? cardTypeArg;
    if (args is Map) {
      if (args['feature'] is String) {
        featureArg = args['feature'] as String;
      }
      if (args['trigger'] is String) {
        triggerArg = args['trigger'] as String;
      }
      if (args['card_type'] is String) {
        cardTypeArg = args['card_type'] as String;
      }
    }
    _trigger = triggerArg ?? (featureArg == null ? 'direct' : 'feature_gate');
    _featureArg = featureArg;
    unawaited(
      AnalyticsService.instance.logPaywallViewed(
        trigger: _trigger,
        feature: featureArg,
        cardType: cardTypeArg,
      ),
    );
    _productWorker = ever<List<ProductDetails>>(
      _premiumController.availableProductsRx,
      (_) => _ensureDefaultSelectedProduct(),
    );
    _ensureDefaultSelectedProduct();
  }

  @override
  void dispose() {
    if (!_purchased && !_premiumController.isPremium) {
      AnalyticsService.instance
          .logPaywallDismissed(trigger: _trigger, feature: _featureArg);
    }
    _productWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: night.bg,
        body: Obx(() {
          final isLoading = _premiumController.isLoading;
          final isPremium = _premiumController.isPremium;
          final currentPlanId = _premiumController.currentPlanId;
          final showPicker = !isPremium || _changingPlan;
          final weekly = _premiumController.weeklyProduct;
          final monthly = _premiumController.monthlyProduct;
          final yearly = _premiumController.yearlyProduct;

          // Weekly → monthly → yearly. Yearly sits on the right as the
          // BEST VALUE anchor (still the default selection). When changing
          // plan, the current one is left out so it can't be bought twice.
          final orderedPlans = <ProductDetails>[
            if (weekly != null) weekly,
            if (monthly != null) monthly,
            if (yearly != null) yearly,
          ].where((p) => !isPremium || p.id != currentPlanId).toList();
          final selected = _selectedProduct != null &&
                  orderedPlans.any((p) => p.id == _selectedProduct!.id)
              ? _selectedProduct
              : null;
          final bestValueId = _bestValueProductId(weekly, monthly, yearly);
          final subtitleKey =
              _triggerSubtitles[_featureArg] ?? 'cwPaySubDefault';

          return Stack(
            children: [
              const Positioned.fill(child: _NightBackdrop()),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TopBar(
                        onClose: () => Get.back(),
                        onRestore: _handleRestore,
                      ),
                    ),
                    const SliverToBoxAdapter(child: _CardFan()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: Column(
                          children: [
                            Text(
                              'cwPayTitle'.tr(),
                              textAlign: TextAlign.center,
                              style: CwType.display
                                  .copyWith(color: night.ink, fontSize: 30),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitleKey.tr(),
                              textAlign: TextAlign.center,
                              style: CwType.callout
                                  .copyWith(color: night.ink2, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: _FeatureList()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: !showPicker
                            ? _PremiumActiveCard(
                                planLabel: _planLabel(currentPlanId),
                                onManage: PremiumService.hasActiveSubscription
                                    ? _openManageSubscription
                                    : null,
                                onChangePlan:
                                    PremiumService.hasActiveSubscription
                                        ? _startPlanChange
                                        : null,
                              )
                            : Column(
                                children: [
                                  if (orderedPlans.isEmpty)
                                    const _ProductsUnavailable()
                                  else
                                    _PlanRow(
                                      plans: orderedPlans,
                                      weeklyId: weekly?.id,
                                      yearlyId: yearly?.id,
                                      bestValueId: bestValueId,
                                      selected: selected,
                                      onSelected: _onPlanSelected,
                                    ),
                                  const SizedBox(height: 16),
                                  _ContinueButton(
                                    label: isPremium
                                        ? 'switchPlanCta'.tr()
                                        : _ctaLabel(selected),
                                    onPressed: selected == null
                                        ? null
                                        : () => _handlePurchase(selected),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'premiumCancelAnytime'.tr(),
                                    style: CwType.caption
                                        .copyWith(color: night.mute),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: _Legal()),
                  ],
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: night.bg.withValues(alpha: 0.6),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  String _ctaLabel(ProductDetails? p) {
    if (p == null) return 'getPremium'.tr();
    if (p.id == PremiumService.yearlyProductId) return 'premiumCtaYearly'.tr();
    if (p.id == PremiumService.monthlyProductId) {
      return 'premiumCtaMonthly'.tr();
    }
    if (p.id == PremiumService.weeklyProductId) return 'premiumCtaWeekly'.tr();
    return 'getPremium'.tr();
  }

  Future<void> _handleRestore() async {
    final result = await _premiumController.restorePurchases();
    if (!mounted) return;
    switch (result) {
      case PremiumRestoreResult.restored:
        context.showSuccessSnackBar('purchaseRestored');
        break;
      case PremiumRestoreResult.notFound:
        context.showInfoSnackBar('purchaseRestoreNotFound');
        break;
      case PremiumRestoreResult.failed:
        context.showErrorSnackBar('purchaseRestoreFailed');
        break;
    }
  }

  String _planLabel(String? productId) {
    if (productId == PremiumService.yearlyProductId) {
      return 'yearlyPlanTitle'.tr();
    }
    if (productId == PremiumService.monthlyProductId) {
      return 'monthlyPlanTitle'.tr();
    }
    if (productId == PremiumService.weeklyProductId) {
      return 'weeklyPlanTitle'.tr();
    }
    return 'lifetimePlanTitle'.tr();
  }

  void _startPlanChange() {
    HapticFeedback.selectionClick();
    // Android can only switch in-app once Play has handed us the current
    // purchase token; otherwise the store's own screen is the safe path.
    if (!PremiumService.canChangePlanInApp) {
      context.showInfoSnackBar('planChangeViaStore');
      _openManageSubscription();
      return;
    }
    setState(() {
      _changingPlan = true;
      _selectedProduct = null;
    });
  }

  Future<void> _openManageSubscription() async {
    final uri = Theme.of(context).platform == TargetPlatform.iOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    final launched = await AppLockService.guard(
      () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
    if (!launched && mounted) context.showErrorSnackBar('couldNotLaunchUrl');
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    final result = await _premiumController.purchase(product);
    if (!mounted) return;
    switch (result) {
      case PremiumPurchaseResult.success:
        _purchased = true;
        unawaited(
          AnalyticsService.instance.logPurchaseSuccess(
            productId: product.id,
            price: product.rawPrice,
            currency: product.currencyCode,
          ),
        );
        HapticFeedback.mediumImpact();
        (Get.context ?? context).showSuccessSnackBar('premiumActivated');
        // Let the snackbar animate in before tearing the page down so the
        // user gets visible confirmation that the purchase landed.
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Get.back();
        break;
      case PremiumPurchaseResult.pending:
        // Ask to Buy / pending payment: not a failure. The purchase stream
        // flips premium on by itself once the store approves it.
        context.showInfoSnackBar('purchasePending');
        break;
      case PremiumPurchaseResult.canceled:
        unawaited(
          AnalyticsService.instance.logPurchaseCanceled(product.id),
        );
        // User backed out of the store sheet — no failure UI, they're
        // already aware they cancelled.
        break;
      case PremiumPurchaseResult.error:
        unawaited(
          AnalyticsService.instance.logPurchaseFailed(product.id),
        );
        HapticFeedback.heavyImpact();
        context.showErrorSnackBar('purchaseFailed');
        break;
    }
  }

  void _ensureDefaultSelectedProduct() {
    if (_selectedProduct != null) return;
    // Premium users pick explicitly in "Change plan" — no default that
    // could be their current plan.
    if (_premiumController.isPremium) return;
    final candidate = _premiumController.yearlyProduct ??
        _premiumController.monthlyProduct ??
        _premiumController.weeklyProduct;
    if (candidate != null && mounted) {
      unawaited(
        AnalyticsService.instance.logPaywallPlanSelected(
          productId: candidate.id,
          price: candidate.rawPrice,
          currency: candidate.currencyCode,
        ),
      );
      setState(() => _selectedProduct = candidate);
    }
  }

  void _onPlanSelected(ProductDetails product) {
    if (_selectedProduct?.id == product.id) return;
    HapticFeedback.selectionClick();
    unawaited(
      AnalyticsService.instance.logPaywallPlanSelected(
        productId: product.id,
        price: product.rawPrice,
        currency: product.currencyCode,
      ),
    );
    setState(() => _selectedProduct = product);
  }

  /// The cheapest plan on a per-month basis. Weekly is normalised by
  /// ×52/12 ≈ 4.33 so all three plans share the same yardstick.
  String? _bestValueProductId(
    ProductDetails? weekly,
    ProductDetails? monthly,
    ProductDetails? yearly,
  ) {
    final candidates = <String, double>{};
    if (yearly != null && yearly.rawPrice > 0) {
      candidates[yearly.id] = yearly.rawPrice / 12;
    }
    if (monthly != null && monthly.rawPrice > 0) {
      candidates[monthly.id] = monthly.rawPrice;
    }
    if (weekly != null && weekly.rawPrice > 0) {
      candidates[weekly.id] = weekly.rawPrice * (52 / 12);
    }
    if (candidates.isEmpty) return null;
    final sorted = candidates.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.key;
  }
}

// ---------------------------------------------------------------------------
// Presentation
// ---------------------------------------------------------------------------

class _NightBackdrop extends StatelessWidget {
  const _NightBackdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.95),
            radius: 1.2,
            colors: [Color(0xFF26245E), Color(0xFF0B0C0F)],
            stops: [0, 0.7],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -0.6),
              radius: 0.9,
              colors: [Color(0x401A8A62), Color(0x000B0C0F)],
            ),
          ),
        ),
      );
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onRestore;
  const _TopBar({required this.onClose, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            onPressed: onClose,
            icon: CwIcon(CwIcons.close, color: night.ink2),
          ),
          const Spacer(),
          TextButton(
            onPressed: onRestore,
            child: Text('restorePurchases'.tr(),
                style: CwType.callout.copyWith(color: night.ink2)),
          ),
        ],
      ),
    );
  }
}

/// Up to three of the user's own cards, fanned; materials when the wallet
/// is empty. Seeing *their* cards is the point of the page.
class _CardFan extends StatelessWidget {
  const _CardFan();

  @override
  Widget build(BuildContext context) {
    final items = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().walletItems.take(3).toList()
        : <WalletItem>[];
    final w = math.min(MediaQuery.sizeOf(context).width * 0.62, 280.0);
    Widget face(int i) {
      if (i < items.length) return WalletCardFace(item: items[i], width: w);
      const ids = [10, 11, 14];
      return CardFace(
        material: CardMaterial.of(ids[i]),
        width: w,
        height: w / kCardAspect,
      );
    }

    return SizedBox(
      height: w / kCardAspect + 40,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(-w * 0.38, 18),
            child: Transform.rotate(angle: -0.16, child: face(1)),
          ),
          Transform.translate(
            offset: Offset(w * 0.38, 18),
            child: Transform.rotate(angle: 0.16, child: face(2)),
          ),
          face(0),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _rows = [
    (CwIcons.infinity, 'cwFeatUnlimited', 'cwFeatUnlimitedSub'),
    (CwIcons.cloudUp, 'cwFeatBackup', 'cwFeatBackupSub'),
    (CwIcons.sparkle, 'cwFeatMaterials', 'cwFeatMaterialsSub'),
    (CwIcons.qr, 'cwFeatQr', 'cwFeatQrSub'),
  ];

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          for (final r in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: CwIcon(r.$1, size: 18, color: night.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$2.tr(),
                            style: CwType.callout.copyWith(
                                color: night.ink, fontWeight: FontWeight.w700)),
                        Text(r.$3.tr(),
                            style: CwType.footnote.copyWith(color: night.mute)),
                      ],
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

class _PlanRow extends StatelessWidget {
  final List<ProductDetails> plans;
  final String? weeklyId;
  final String? yearlyId;
  final String? bestValueId;
  final ProductDetails? selected;
  final ValueChanged<ProductDetails> onSelected;

  const _PlanRow({
    required this.plans,
    required this.weeklyId,
    required this.yearlyId,
    required this.bestValueId,
    required this.selected,
    required this.onSelected,
  });

  String _title(ProductDetails p) {
    if (p.id == yearlyId) return 'yearlyPlanTitle'.tr();
    if (p.id == weeklyId) return 'weeklyPlanTitle'.tr();
    return 'monthlyPlanTitle'.tr();
  }

  String _period(ProductDetails p) {
    if (p.id == yearlyId) return 'perYear'.tr();
    if (p.id == weeklyId) return 'perWeek'.tr();
    return 'perMonth'.tr();
  }

  /// Per-month equivalent for yearly / weekly so plans compare fairly.
  String? _perMonth(ProductDetails p, Locale locale) {
    double? amount;
    if (p.id == yearlyId) amount = p.rawPrice / 12;
    if (p.id == weeklyId) amount = p.rawPrice * 4.345;
    if (amount == null || amount <= 0) return null;
    final symbol = RegExp(r'[^\d\s.,]+').firstMatch(p.price.trim())?.group(0) ??
        p.currencyCode;
    final value =
        LocaleFormat.currency(locale, symbol: symbol, decimalDigits: 2)
            .format(amount);
    return '$value ${'perMonth'.tr()}';
  }

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    final locale = context.locale;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < plans.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Builder(builder: (context) {
                final p = plans[i];
                final on = p.id == selected?.id;
                final perMonth = _perMonth(p, locale);
                return Semantics(
                  button: true,
                  selected: on,
                  child: GestureDetector(
                    onTap: () => onSelected(p),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: CwMotion.fast,
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                          decoration: BoxDecoration(
                            color: on
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: on
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.16),
                              width: on ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_title(p),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CwType.footnote.copyWith(
                                      color: night.ink2,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(p.price,
                                    style: CwType.headline.copyWith(
                                        color: night.ink,
                                        fontWeight: FontWeight.w800)),
                              ),
                              Text(_period(p),
                                  style: CwType.caption
                                      .copyWith(color: night.mute)),
                              if (perMonth != null) ...[
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(perMonth,
                                      style: CwType.caption.copyWith(
                                          color: night.ink2,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (p.id == bestValueId)
                          Positioned(
                            top: -10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'cwBestValue'.tr().toUpperCase(),
                                  style: CwType.overline.copyWith(
                                      color: const Color(0xFF0B0C0F),
                                      fontSize: 9.5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _ContinueButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0B0C0F),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CwRadius.l),
            ),
          ),
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                },
          child: Text(label,
              style: CwType.headline.copyWith(
                  color: const Color(0xFF0B0C0F), fontWeight: FontWeight.w700)),
        ),
      );
}

class _ProductsUnavailable extends StatelessWidget {
  const _ProductsUnavailable();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'premiumProductsUnavailable'.tr(),
          textAlign: TextAlign.center,
          style: CwType.callout.copyWith(color: CwColors.night.warn),
        ),
      );
}

/// Premium subscriber state — replaces the plan picker so an active
/// subscriber can't start a second subscription by accident.
class _PremiumActiveCard extends StatelessWidget {
  final String planLabel;
  final VoidCallback? onManage;
  final VoidCallback? onChangePlan;

  const _PremiumActiveCard({
    required this.planLabel,
    this.onManage,
    this.onChangePlan,
  });

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(CwRadius.l),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          CwIcon(CwIcons.gem, size: 30, color: night.accent),
          const SizedBox(height: 10),
          Text('premiumActiveTitle'.tr(),
              textAlign: TextAlign.center,
              style: CwType.title.copyWith(color: night.ink, fontSize: 20)),
          const SizedBox(height: 4),
          Text('premiumActiveSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: CwType.footnote.copyWith(color: night.ink2)),
          const SizedBox(height: 8),
          Text('premiumCurrentPlan'.tr(args: [planLabel]),
              style: CwType.footnote
                  .copyWith(color: night.ink, fontWeight: FontWeight.w700)),
          if (onManage != null || onChangePlan != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onManage != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: night.ink,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      onPressed: onManage,
                      child: Text('manageSubscription'.tr(),
                          textAlign: TextAlign.center),
                    ),
                  ),
                if (onManage != null && onChangePlan != null)
                  const SizedBox(width: 12),
                if (onChangePlan != null)
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0B0C0F),
                      ),
                      onPressed: onChangePlan,
                      child:
                          Text('changePlan'.tr(), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Legal extends StatelessWidget {
  const _Legal();

  Future<void> _open(BuildContext context, String url) async {
    final ok = await AppLockService.guard(
        () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication));
    if (!ok && context.mounted) context.showErrorSnackBar('couldNotLaunchUrl');
  }

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    final link = CwType.caption.copyWith(color: night.ink2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        children: [
          Text(
            (Theme.of(context).platform == TargetPlatform.android
                    ? 'premiumLegalDisclosureAndroid'
                    : 'premiumLegalDisclosureIos')
                .tr(),
            textAlign: TextAlign.center,
            style: CwType.caption.copyWith(
                color: night.mute,
                fontWeight: FontWeight.w400,
                fontSize: 10.5,
                height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _open(context, LegalUrls.termsOfUse),
                child: Text('termsOfUse'.tr(), style: link),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('·', style: link),
              ),
              InkWell(
                onTap: () => _open(context, LegalUrls.privacyPolicy),
                child: Text('privacyPolicy'.tr(), style: link),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
