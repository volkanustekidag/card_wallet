import 'dart:async';

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
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Paywall: a titanium Premium card next to the name, one line on why it
/// opened, what Premium adds (five plain rows), a trust line, the store's
/// plans (yearly first, per-month and saving shown), one button and the
/// renewal terms under it. Pricing, plans and gating are unchanged.
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

  /// `loyalty` / `credit` / `iban` when the free card limit opened this.
  String? _cardType;
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
    _cardType = cardTypeArg;
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

          return Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      onClose: () => Get.back(),
                      onRestore: _handleRestore,
                    ),
                    // The pitch. Short of room (small phone, big text) the
                    // perks drop their second line; it scrolls only if even
                    // that doesn't fit.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final short = box.maxHeight < 440;
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Header(context: _contextLine()),
                                SizedBox(height: short ? 24 : 28),
                                _Perks(compact: short),
                                const SizedBox(height: 8),
                                const _Trust(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Always on screen: plans, the button, the terms.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                                  _PlanList(
                                    plans: orderedPlans,
                                    weeklyId: weekly?.id,
                                    monthly: monthly,
                                    yearlyId: yearly?.id,
                                    selected: selected,
                                    onSelected: _onPlanSelected,
                                  ),
                                const SizedBox(height: 16),
                                _ContinueButton(
                                  label: isPremium
                                      ? 'switchPlanCta'.tr()
                                      : 'cwContinue'.tr(),
                                  onPressed: selected == null
                                      ? null
                                      : () => _handlePurchase(selected),
                                ),
                              ],
                            ),
                    ),
                    _Legal(
                      renews: showPicker && selected != null
                          ? _renewsLine(selected, weekly?.id, yearly?.id)
                          : null,
                    ),
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

  /// Why the paywall opened, in one line (null when opened directly).
  _ContextLine? _contextLine() {
    switch (_featureArg) {
      case 'unlimitedCards':
        return switch (_cardType) {
          'credit' => _ContextLine('cwPayCtxCredit'.tr(), limit: true),
          'iban' => _ContextLine('cwPayCtxIban'.tr(), limit: true),
          _ => _ContextLine(
              'cwPayCtxLoyalty'
                  .tr(args: ['${PremiumService.maxLoyaltyCardsForFree}']),
              limit: true),
        };
      case 'backupRestore':
        return _ContextLine('cwPayCtxBackup'.tr());
      case 'walletExport':
        return _ContextLine('cwPayCtxWallet'.tr());
      case 'qrCreate':
        return _ContextLine('cwPayCtxQr'.tr());
      case 'premiumColors':
        return _ContextLine('cwPayCtxMetal'.tr());
    }
    return null;
  }

  /// "€29.99 per year, renews automatically. Cancel anytime."
  String _renewsLine(ProductDetails p, String? weeklyId, String? yearlyId) {
    final key = p.id == yearlyId
        ? 'cwRenewsYear'
        : p.id == weeklyId
            ? 'cwRenewsWeek'
            : 'cwRenewsMonth';
    return key.tr(args: [p.price]);
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
}

// ---------------------------------------------------------------------------
// Presentation
// ---------------------------------------------------------------------------

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

class _ContextLine {
  final String text;

  /// The free card limit (warning colour) rather than a feature gate.
  final bool limit;
  const _ContextLine(this.text, {this.limit = false});
}

/// Name on the left, the titanium Premium card on the right; under them
/// either the tagline or why the paywall opened.
class _Header extends StatelessWidget {
  final _ContextLine? context;
  const _Header({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final c = CwColors.of(ctx);
    final line = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'cwPayTitle2'.tr(),
                style: CwType.display.copyWith(
                    color: c.ink,
                    fontSize: 30,
                    height: 1.05,
                    letterSpacing: -0.8),
              ),
            ),
            const SizedBox(width: 12),
            const _TitaniumCard(),
          ],
        ),
        const SizedBox(height: 8),
        if (line == null)
          Text('cwPaySub'.tr(),
              style: CwType.callout.copyWith(color: c.mute, height: 1.4))
        else
          _ContextPill(line: line),
      ],
    );
  }
}

/// Why the paywall opened: a quiet chip in the page's own colours (no
/// tinted fill), with only the small icon carrying a hint of colour.
class _ContextPill extends StatelessWidget {
  final _ContextLine line;
  const _ContextPill({required this.line});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CwIcon(line.limit ? CwIcons.lock : CwIcons.sparkle,
              size: 14, color: line.limit ? c.warn : c.ink2),
          const SizedBox(width: 6),
          Flexible(
            child: Text(line.text,
                style: CwType.footnote
                    .copyWith(color: c.ink2, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// A small brushed-titanium Premium card: the product, shown as one.
class _TitaniumCard extends StatelessWidget {
  const _TitaniumCard();

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -0.1,
        child: Container(
          width: 112,
          height: 71,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment(-1, -0.6),
              end: Alignment(1, 0.6),
              colors: [
                Color(0xFF5C6067),
                Color(0xFFC9CCD1),
                Color(0xFF8A8E95),
                Color(0xFFECEEF1),
                Color(0xFF8F939A),
                Color(0xFFC4C7CC),
                Color(0xFF62666D),
              ],
              stops: [0, 0.24, 0.4, 0.54, 0.68, 0.84, 1],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 24,
                  offset: Offset(0, 10)),
            ],
          ),
          child: Stack(
            children: [
              // Brushed grain.
              Positioned.fill(
                child: CustomPaint(painter: _BrushedPainter()),
              ),
              // Light sweep.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1, -1),
                      end: const Alignment(1, 1),
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.38, 0.5, 0.62],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 11,
                top: 15,
                child: Container(
                  width: 18,
                  height: 13,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEFE0A8),
                        Color(0xFFB8994D),
                        Color(0xFFDCC684),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0x8C1E2024), width: 1.5),
                  ),
                ),
              ),
              const Positioned(
                left: 11,
                bottom: 9,
                child: Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Color(0xBF1E2024),
                    shadows: [
                      Shadow(color: Color(0x99FFFFFF), offset: Offset(0, .5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BrushedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x08FFFFFF)
      ..strokeWidth = 0.6;
    for (var x = 0.0; x < size.width; x += 2) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_BrushedPainter old) => false;
}

/// What Premium adds: one plain line icon, a title and a short line each.
class _Perks extends StatelessWidget {
  /// Titles only (short screens).
  final bool compact;
  const _Perks({required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final apple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final perks = [
      (CwIcons.infinity, 'cwTagUnlimited', 'cwPerkUnlimited'),
      (CwIcons.cloudUp, 'cwTagBackup', 'cwPerkBackup'),
      (CwIcons.sparkle, 'cwTagMetal', 'cwPerkMetal'),
      (
        CwIcons.walletPass,
        apple ? 'cwTagAppleWallet' : 'cwTagGoogleWallet',
        'cwPerkWallet'
      ),
      (CwIcons.qr, 'cwTagQr', 'cwPerkQr'),
    ];
    return Column(
      children: [
        for (final p in perks)
          Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 5 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: CwIcon(p.$1, size: 22, color: c.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.$2.tr(),
                          style: CwType.callout.copyWith(
                              color: c.ink, fontWeight: FontWeight.w600)),
                      if (!compact)
                        Text(p.$3.tr(),
                            style: CwType.footnote.copyWith(color: c.mute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Row(
      children: [
        CwIcon(CwIcons.shield, size: 14, color: c.mute),
        const SizedBox(width: 6),
        Flexible(
          child: Text('cwPayTrust'.tr(),
              style: CwType.caption.copyWith(color: c.mute)),
        ),
      ],
    );
  }
}

/// The store's plans as rows: yearly first (with its monthly equivalent
/// and the saving against monthly), then monthly, then weekly.
class _PlanList extends StatelessWidget {
  final List<ProductDetails> plans;
  final String? weeklyId;
  final ProductDetails? monthly;
  final String? yearlyId;
  final ProductDetails? selected;
  final ValueChanged<ProductDetails> onSelected;

  const _PlanList({
    required this.plans,
    required this.weeklyId,
    required this.monthly,
    required this.yearlyId,
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

  /// "€2.50 / month" under yearly.
  String? _perMonth(ProductDetails p, Locale locale) {
    if (p.id != yearlyId || p.rawPrice <= 0) return null;
    final symbol = RegExp(r'[^\d\s.,]+').firstMatch(p.price.trim())?.group(0) ??
        p.currencyCode;
    final value =
        LocaleFormat.currency(locale, symbol: symbol, decimalDigits: 2)
            .format(p.rawPrice / 12);
    return '$value ${'perMonth'.tr()}';
  }

  /// Yearly vs twelve months of monthly, from the store's own prices.
  int? _saving(ProductDetails p) {
    final m = monthly;
    if (p.id != yearlyId || m == null || m.rawPrice <= 0) return null;
    final pct = ((1 - p.rawPrice / (m.rawPrice * 12)) * 100).round();
    return pct >= 5 ? pct : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final locale = context.locale;
    int rank(ProductDetails p) =>
        p.id == yearlyId ? 0 : (p.id == weeklyId ? 2 : 1);
    final ordered = [...plans]..sort((a, b) => rank(a).compareTo(rank(b)));
    return Column(
      children: [
        for (final p in ordered) ...[
          if (p != ordered.first) const SizedBox(height: 8),
          Builder(builder: (context) {
            final on = p.id == selected?.id;
            final perMonth = _perMonth(p, locale);
            final saving = _saving(p);
            return Semantics(
              button: true,
              selected: on,
              child: GestureDetector(
                onTap: () => onSelected(p),
                child: AnimatedContainer(
                  duration: CwMotion.fast,
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    // Same width selected or not: only the colour changes,
                    // so picking a plan never shifts the screen.
                    border: Border.all(
                        color: on ? c.ink : c.ink.withValues(alpha: 0.06),
                        width: 2),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: CwMotion.fast,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: on ? c.ink : c.mute.withValues(alpha: 0.6),
                            width: on ? 6 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_title(p),
                                style: CwType.callout.copyWith(
                                    color: c.ink, fontWeight: FontWeight.w700)),
                            if (perMonth != null)
                              Text(perMonth,
                                  style:
                                      CwType.caption.copyWith(color: c.mute)),
                          ],
                        ),
                      ),
                      if (saving != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: c.ok, width: 1.5),
                          ),
                          child: Text('cwSaveBadge'.tr(args: ['$saving']),
                              style: CwType.overline
                                  .copyWith(color: c.ok, fontSize: 9.5)),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(p.price,
                              style: CwType.callout.copyWith(
                                  color: c.ink, fontWeight: FontWeight.w800)),
                          Text(_period(p),
                              style: CwType.caption
                                  .copyWith(color: c.mute, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
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
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          disabledBackgroundColor: c.brand.withValues(alpha: 0.3),
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
                .copyWith(color: c.onBrand, fontWeight: FontWeight.w700)),
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

/// The renewal terms for the selected plan right under the button, then
/// the terms and privacy links.
class _Legal extends StatelessWidget {
  final String? renews;
  const _Legal({required this.renews});

  Future<void> _open(BuildContext context, String url) async {
    final ok = await AppLockService.guard(
        () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication));
    if (!ok && context.mounted) context.showErrorSnackBar('couldNotLaunchUrl');
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final small = CwType.caption.copyWith(color: c.mute, height: 1.5);
    final link = small.copyWith(color: c.ink2, fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        children: [
          if (renews != null)
            Text(renews!, textAlign: TextAlign.center, style: small),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _open(context, LegalUrls.termsOfUse),
                child: Text('cwTerms'.tr(), style: link),
              ),
              Text('  ·  ', style: small),
              InkWell(
                onTap: () => _open(context, LegalUrls.privacyPolicy),
                child: Text('cwPrivacy'.tr(), style: link),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
