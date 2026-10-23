import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Paywall v2: the user's own cards fanned out on a stage in the app's theme, one line
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
    final c = CwColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: cwOverlayStyle(context),
      child: Scaffold(
        backgroundColor: c.bg,
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

          return Stack(
            children: [
              const Positioned.fill(child: _Backdrop()),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      onClose: () => Get.back(),
                      onRestore: _handleRestore,
                    ),
                    // The cards, with what Premium adds floating around
                    // them, take what's left above the purchase block.
                    Expanded(
                      child: _Hero(
                        highlight: _featureArg,
                        footer: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                          child: Text(
                            'cwPayHeadline'.tr(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: CwType.display.copyWith(
                                color: c.ink, fontSize: 28, height: 1.1),
                          ),
                        ),
                      ),
                    ),
                    // Always on screen: plans, the button, the terms.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: !showPicker
                          ? _PremiumActiveCard(
                              planLabel: _planLabel(currentPlanId),
                              onManage: PremiumService.hasActiveSubscription
                                  ? _openManageSubscription
                                  : null,
                              onChangePlan: PremiumService.hasActiveSubscription
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
                                const SizedBox(height: 12),
                                _ContinueButton(
                                  label: isPremium
                                      ? 'switchPlanCta'.tr()
                                      : _ctaLabel(selected),
                                  onPressed: selected == null
                                      ? null
                                      : () => _handlePurchase(selected),
                                ),
                              ],
                            ),
                    ),
                    const _Legal(),
                  ],
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: c.bg.withValues(alpha: 0.6),
                    child: Center(
                      child: CircularProgressIndicator(color: c.ink),
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

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.95),
          radius: 1.2,
          colors: [
            Color.alphaBlend(
                c.accent.withValues(alpha: dark ? 0.25 : 0.10), c.bg),
            c.bg,
          ],
          stops: const [0, 0.7],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.6),
            radius: 0.9,
            colors: [
              c.ok.withValues(alpha: dark ? 0.25 : 0.10),
              c.ok.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onRestore;
  const _TopBar({required this.onClose, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            onPressed: onClose,
            icon: CwIcon(CwIcons.close, color: c.ink2),
          ),
          const Spacer(),
          TextButton(
            onPressed: onRestore,
            child: Text('restorePurchases'.tr(),
                style: CwType.callout.copyWith(color: c.ink2)),
          ),
        ],
      ),
    );
  }
}

/// Up to three of the user's own cards, fanned; materials when the wallet
/// is empty. Seeing *their* cards is the point of the page.
class _CardFan extends StatelessWidget {
  final double width;
  const _CardFan({required this.width});

  @override
  Widget build(BuildContext context) {
    final items = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().walletItems.take(3).toList()
        : <WalletItem>[];
    final w = width;
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
      width: w,
      height: w / kCardAspect + 20,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(-w * 0.32, 10),
            child: Transform.rotate(angle: -0.16, child: face(1)),
          ),
          Transform.translate(
            offset: Offset(w * 0.32, 10),
            child: Transform.rotate(angle: 0.16, child: face(2)),
          ),
          face(0),
        ],
      ),
    );
  }
}

/// What Premium adds, as glass tags floating around the card fan. The tag
/// for the feature that opened the paywall ([highlight]) is lit.
class _Hero extends StatefulWidget {
  final String? highlight;

  /// Sits right under the stage (the headline); the pair is centred.
  final Widget footer;
  const _Hero({required this.highlight, required this.footer});

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  /// (feature arg that lights it, icon, label key, alignment in the hero)
  static List<(String, CwIcons, String, Alignment)> _tags(bool apple) => [
        (
          'unlimitedCards',
          CwIcons.infinity,
          'cwTagUnlimited',
          const Alignment(-0.85, -1)
        ),
        (
          'backupRestore',
          CwIcons.cloudUp,
          'cwTagBackup',
          const Alignment(0.9, -0.62)
        ),
        (
          'premiumColors',
          CwIcons.sparkle,
          'cwTagMetal',
          const Alignment(-1, 0.42)
        ),
        (
          'walletExport',
          CwIcons.walletPass,
          apple ? 'cwTagAppleWallet' : 'cwTagGoogleWallet',
          const Alignment(0.95, 0.72)
        ),
        ('qrCreate', CwIcons.qr, 'cwTagQr', const Alignment(-0.2, 1.05)),
      ];

  @override
  Widget build(BuildContext context) {
    final apple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(builder: (context, box) {
      final tags = _tags(apple);
      // The fan (side cards included) stays inside the screen and leaves
      // room above and below for a row of tags.
      final w = math.min(
        math.min((box.maxWidth - 28) / 1.75, 240.0),
        (box.maxHeight - 200) * kCardAspect,
      );
      final stage = Size(box.maxWidth, w / kCardAspect + 130);
      // A little below centre: leftover height opens under the close
      // button, not between the headline and the plans.
      return Align(
        alignment: const Alignment(0, 0.45),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.fromSize(
                size: stage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (w >= 110) Center(child: _CardFan(width: w)),
                    for (var i = 0; i < tags.length; i++)
                      Align(
                        alignment: tags[i].$4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: AnimatedBuilder(
                            animation: _float,
                            builder: (_, child) => Transform.translate(
                              offset: reduceMotion
                                  ? Offset.zero
                                  : Offset(
                                      0,
                                      4 *
                                          math.sin(2 * math.pi * _float.value +
                                              i * 1.3)),
                              child: child,
                            ),
                            child: _Tag(
                              icon: tags[i].$2,
                              label: tags[i].$3.tr(),
                              lit: tags[i].$1 == widget.highlight,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              widget.footer,
            ],
          ),
        ),
      );
    });
  }
}

class _Tag extends StatelessWidget {
  final CwIcons icon;
  final String label;
  final bool lit;
  const _Tag({required this.icon, required this.label, required this.lit});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final fg = lit ? Colors.white : c.ink;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 13, 7),
          decoration: BoxDecoration(
            color: lit ? c.accent : c.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: lit ? c.accent : c.ink.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CwIcon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: CwType.footnote
                      .copyWith(color: fg, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
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
    final c = CwColors.of(context);
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
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                          decoration: BoxDecoration(
                            color: on
                                ? c.ink.withValues(alpha: 0.10)
                                : c.ink.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            // Same width selected or not: a thicker border
                            // grew the tile and shifted the whole screen.
                            border: Border.all(
                              color: on ? c.ink : c.ink.withValues(alpha: 0.16),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_title(p),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CwType.footnote.copyWith(
                                      color: c.ink2,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(p.price,
                                    style: CwType.headline.copyWith(
                                        color: c.ink,
                                        fontWeight: FontWeight.w800)),
                              ),
                              Text(_period(p),
                                  style:
                                      CwType.caption.copyWith(color: c.mute)),
                              if (perMonth != null) ...[
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(perMonth,
                                      style: CwType.caption.copyWith(
                                          color: c.ink2,
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
                                  color: c.ink,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'cwBestValue'.tr().toUpperCase(),
                                  style: CwType.overline
                                      .copyWith(color: c.bg, fontSize: 9.5),
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
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          disabledBackgroundColor: c.ink.withValues(alpha: 0.3),
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
            style: CwType.headline
                .copyWith(color: c.bg, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ProductsUnavailable extends StatelessWidget {
  const _ProductsUnavailable();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'premiumProductsUnavailable'.tr(),
          textAlign: TextAlign.center,
          style: CwType.callout.copyWith(color: CwColors.of(context).warn),
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
    final c = CwColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(CwRadius.l),
        border: Border.all(color: c.ink.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          CwIcon(CwIcons.gem, size: 30, color: c.accent),
          const SizedBox(height: 10),
          Text('premiumActiveTitle'.tr(),
              textAlign: TextAlign.center,
              style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
          const SizedBox(height: 4),
          Text('premiumActiveSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: CwType.footnote.copyWith(color: c.ink2)),
          const SizedBox(height: 8),
          Text('premiumCurrentPlan'.tr(args: [planLabel]),
              style: CwType.footnote
                  .copyWith(color: c.ink, fontWeight: FontWeight.w700)),
          if (onManage != null || onChangePlan != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onManage != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.ink,
                        side: BorderSide(color: c.ink.withValues(alpha: 0.3)),
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
                        backgroundColor: c.ink,
                        foregroundColor: c.bg,
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

/// The store's full auto-renew wording. Price, period and "auto-renews"
/// sit next to the button; this is one tap away under it.
Future<void> _showSubscriptionDetails(BuildContext context) =>
    showCwSheet<void>(
      context,
      builder: (sheet) {
        final c = CwColors.of(sheet);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('cwSubscriptionDetails'.tr(),
                    style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
                const SizedBox(height: 10),
                Text(
                  (Theme.of(sheet).platform == TargetPlatform.android
                          ? 'premiumLegalDisclosureAndroid'
                          : 'premiumLegalDisclosureIos')
                      .tr(),
                  style: CwType.footnote.copyWith(color: c.ink2, height: 1.45),
                ),
              ],
            ),
          ),
        );
      },
    );

/// "Cancel anytime · Auto-renews", subscription details and the terms /
/// privacy links, under the button.
class _Legal extends StatelessWidget {
  const _Legal();

  Future<void> _open(BuildContext context, String url) async {
    final ok = await AppLockService.guard(
        () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication));
    if (!ok && context.mounted) context.showErrorSnackBar('couldNotLaunchUrl');
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final small = CwType.caption.copyWith(color: c.mute);
    final link = CwType.caption.copyWith(color: c.ink2);
    Widget dot() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: small),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('premiumCancelAnytime'.tr(), style: small),
          dot(),
          InkWell(
            onTap: () => _showSubscriptionDetails(context),
            child: Text('cwSubscriptionDetails'.tr(), style: link),
          ),
          dot(),
          InkWell(
            onTap: () => _open(context, LegalUrls.termsOfUse),
            child: Text('termsOfUse'.tr(), style: link),
          ),
          dot(),
          InkWell(
            onTap: () => _open(context, LegalUrls.privacyPolicy),
            child: Text('privacyPolicy'.tr(), style: link),
          ),
        ],
      ),
    );
  }
}
