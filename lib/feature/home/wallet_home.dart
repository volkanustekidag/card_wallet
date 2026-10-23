import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';
import 'package:wallet_app/core/utils/loyalty_usage.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sheets/credit_card_reminder_sheet.dart';
import 'package:wallet_app/feature/scanner/add_flows.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/feature/search/wallet_search_page.dart';
import 'package:wallet_app/ui/card/card_face.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/components/cw_top_bar.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/navigation/open_wallet_item.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';
import 'package:wallet_app/core/utils/credit_card_label.dart';

/// Visible height of each card in the stack before the next one covers it.
const double _kStripHeight = 58;

/// Home v2: the screen is the wallet. Title + search/settings, a segment
/// control, the "Up Next" guess, one line of notices and the card stack.
/// A single "+" adds cards; pulling down past the top opens search.
class WalletHome extends StatefulWidget {
  final HomeController controller;

  const WalletHome({super.key, required this.controller});

  @override
  State<WalletHome> createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> {
  final ValueNotifier<HomeFilter> _filter = ValueNotifier(HomeFilter.all);
  bool _pullArmed = true;

  HomeController get _c => widget.controller;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final px = n.metrics.pixels;
    if (n is ScrollUpdateNotification &&
        n.dragDetails != null &&
        px < -84 &&
        _pullArmed) {
      _pullArmed = false;
      HapticFeedback.mediumImpact();
      openWalletSearch();
    } else if (px >= 0) {
      _pullArmed = true;
    }
    return false;
  }

  Future<void> _openSettings() async {
    await Get.toNamed('/settings');
    _c.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: c.bg,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CwLargeTitleBar(
                  title: 'cwWalletTitle'.tr(),
                  inline: true,
                  actions: [
                    CwCircleButton(
                      CwIcons.search,
                      key: const ValueKey('homeSearchButton'),
                      onPressed: openWalletSearch,
                      semanticLabel: 'cwSearch'.tr(),
                    ),
                    CwCircleButton(
                      CwIcons.settings,
                      key: const ValueKey('homeSettingsButton'),
                      onPressed: _openSettings,
                      semanticLabel: 'settings'.tr(),
                    ),
                  ],
                ),
                Obx(() {
                  final items = _c.walletItems.toList();
                  final showUpNext = UiPrefs.instance.upNext.value;
                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyWallet());
                  }
                  return ValueListenableBuilder<HomeFilter>(
                    valueListenable: _filter,
                    builder: (context, filter, _) => _WalletSlivers(
                      controller: _c,
                      items: items,
                      showUpNext: showUpNext,
                      filter: filter,
                      onFilter: (f) => _filter.value = f,
                    ),
                  );
                }),
                SliverToBoxAdapter(child: SizedBox(height: 110 + bottomInset)),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20 + bottomInset,
            child: _AddFab(onTap: () => openScanner()),
          ),
        ],
      ),
    );
  }
}

/// Segments, Up Next, the count/notice line and the stack for one filter.
class _WalletSlivers extends StatelessWidget {
  final HomeController controller;
  final List<WalletItem> items;
  final HomeFilter filter;
  final ValueChanged<HomeFilter> onFilter;
  final bool showUpNext;

  const _WalletSlivers({
    required this.controller,
    required this.items,
    required this.showUpNext,
    required this.filter,
    required this.onFilter,
  });

  static const _segments = [
    HomeFilter.all,
    HomeFilter.loyalty,
    HomeFilter.credit,
    HomeFilter.iban,
  ];

  static String _segLabel(HomeFilter f) {
    switch (f) {
      case HomeFilter.loyalty:
        return 'cwSegLoyalty'.tr();
      case HomeFilter.credit:
        return 'cwSegCards'.tr();
      case HomeFilter.iban:
        return 'cwSegBank'.tr();
      case HomeFilter.all:
      case HomeFilter.favorites:
        return 'cwSegAll'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stack = stackOrder(items, filter);
    final upNext =
        showUpNext && (filter == HomeFilter.all || filter == HomeFilter.loyalty)
            ? _upNext(now)
            : null;
    final notice = (filter == HomeFilter.all || filter == HomeFilter.credit)
        ? _topNotice()
        : null;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                CwSpace.gutter, 16, CwSpace.gutter, 0),
            child: CwSegmented<HomeFilter>(
              values: _segments,
              selected: filter,
              label: _segLabel,
              onChanged: onFilter,
            ),
          ),
        ),
        if (upNext != null)
          SliverToBoxAdapter(
            child: _UpNextBanner(card: upNext.$1, reason: upNext.$2),
          ),
        SliverToBoxAdapter(
          child: _CountLine(count: stack.length, notice: notice),
        ),
        if (stack.isEmpty)
          SliverToBoxAdapter(
            child: CwEmptyState(
              icon: CwIcons.stack,
              title: 'cwSegEmpty'.tr(),
              action: CwButton(
                'cwAddCard'.tr(),
                icon: CwIcons.plus,
                expand: false,
                height: 46,
                onPressed: () => goToAddCard(
                  context: context,
                  type: filter == HomeFilter.iban
                      ? CardLimitType.iban
                      : filter == HomeFilter.credit
                          ? CardLimitType.credit
                          : CardLimitType.loyalty,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = stack[i];
                  final last = i == stack.length - 1;
                  return last
                      ? _FrontCard(key: ValueKey(item.heroTag), item: item)
                      : _StackStrip(
                          key: ValueKey(item.heroTag),
                          item: item,
                          badge: _badgeFor(item),
                        );
                },
                childCount: stack.length,
                addAutomaticKeepAlives: false,
              ),
            ),
          ),
      ],
    );
  }

  (LoyaltyCard, String)? _upNext(DateTime now) {
    final loyalties = controller.loyaltyCards;
    if (loyalties.isEmpty) return null;
    final ranked = sortLoyaltyForNow(loyalties, now);
    final top = ranked.first;
    final score = upNextScore(top, now);
    final String reason;
    if ((top.usageLog?.length ?? 0) >= 3 && score >= 0.8) {
      reason = 'cwUpNextHabit'.tr();
    } else if ((top.useCount ?? 0) > 0) {
      reason = 'cwUpNextMostUsed'.tr();
    } else {
      reason = 'cwUpNextReady'.tr();
    }
    return (top, reason);
  }

  _Notice? _topNotice() {
    final pay = controller.upcomingPaymentNotices;
    if (pay.isNotEmpty) {
      return _Notice(pay.first, CardReminderKind.payment);
    }
    final exp = controller.upcomingExpiryNotices;
    if (exp.isNotEmpty) return _Notice(exp.first, CardReminderKind.expiry);
    return null;
  }

  String? _badgeFor(WalletItem item) {
    if (item.kind != WalletItemKind.credit) return null;
    final card = item.card as CreditCard;
    for (final n in controller.upcomingPaymentNotices) {
      if (n.card.id == card.id) {
        return n.daysUntil <= 0
            ? 'cwDueToday'.tr()
            : 'cwDueBadge'.tr(args: ['${n.daysUntil}']);
      }
    }
    for (final n in controller.upcomingExpiryNotices) {
      if (n.card.id == card.id) return 'cwExpiresSoon'.tr();
    }
    return null;
  }
}

/// Stack order for a filter: loyalty first (best guess for now on top),
/// then IBANs, then bank cards — the front card is the one shown in full.
/// Favourites lead within each kind.
List<WalletItem> stackOrder(List<WalletItem> items, HomeFilter filter) {
  final loyalty = <LoyaltyCard>[];
  final ibans = <WalletItem>[];
  final credits = <WalletItem>[];
  for (final it in items) {
    if (!filter.matches(it)) continue;
    switch (it.kind) {
      case WalletItemKind.loyalty:
        loyalty.add(it.card as LoyaltyCard);
        break;
      case WalletItemKind.iban:
        ibans.add(it);
        break;
      case WalletItemKind.credit:
        credits.add(it);
        break;
    }
  }
  // Partition instead of sort: keeps the incoming order (newest first /
  // best guess first) inside each group — List.sort isn't stable.
  List<T> favFirst<T>(List<T> l, bool Function(T) fav) =>
      [...l.where(fav), ...l.where((e) => !fav(e))];
  return [
    ...favFirst(sortLoyaltyForNow(loyalty, DateTime.now()), isFavoriteCard)
        .map(WalletItem.loyalty),
    ...favFirst(ibans, (w) => w.isFavorite),
    ...favFirst(credits, (w) => w.isFavorite),
  ];
}

class _Notice {
  final UpcomingCardDate date;
  final CardReminderKind kind;
  const _Notice(this.date, this.kind);
}

class _UpNextBanner extends StatelessWidget {
  final LoyaltyCard card;
  final String reason;

  const _UpNextBanner({required this.card, required this.reason});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final item = WalletItem.loyalty(card);
    void open() => openWalletItem(context, item);
    return Padding(
      padding: const EdgeInsets.fromLTRB(CwSpace.gutter, 14, CwSpace.gutter, 0),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(CwRadius.l),
        child: InkWell(
          key: const ValueKey('homeUpNext'),
          borderRadius: BorderRadius.circular(CwRadius.l),
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                CardThumb(item: item, width: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cwUpNext'.tr().toUpperCase(),
                        style: CwType.overline.copyWith(color: c.accent),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titleForItem(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CwType.headline.copyWith(color: c.ink),
                      ),
                      Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CwType.footnote.copyWith(color: c.mute),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ShowPill(onTap: open),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowPill extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Material(
      color: c.brand,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'cwShow'.tr(),
            style: CwType.footnote.copyWith(
              color: c.onBrand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CountLine extends StatelessWidget {
  final int count;
  final _Notice? notice;

  const _CountLine({required this.count, this.notice});

  static String whenText(int days) {
    if (days <= 0) return 'cwWhenToday'.tr();
    if (days == 1) return 'cwWhenTomorrow'.tr();
    return 'cwWhenInDays'.plural(days);
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final n = notice;
    Widget? right;
    if (n != null) {
      final card = n.date.card;
      final name = card.bankName.trim().isNotEmpty
          ? card.bankName.trim()
          : '${creditCardLabel(card)} •• ${last4Of(card.creditCardNumber)}';
      final text = (n.kind == CardReminderKind.payment
              ? 'cwNoticePayment'
              : 'cwNoticeExpiry')
          .tr(namedArgs: {'card': name, 'when': whenText(n.date.daysUntil)});
      right = Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showCreditCardReminderSheet(
            context,
            card: card,
            kind: n.kind,
            targetDate: n.date.targetDate,
            daysUntil: n.date.daysUntil,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: c.warn, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CwType.caption.copyWith(color: c.warn),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 10),
      child: Row(
        children: [
          Text(
            'cwCardsCount'.plural(count).toUpperCase(),
            style: CwType.overline.copyWith(color: c.mute),
          ),
          const SizedBox(width: 12),
          if (right != null) right,
        ],
      ),
    );
  }
}

/// A card tucked in the stack: only its header strip shows. The face is
/// drawn a little taller than the strip so its rounded bottom slides under
/// the next card instead of showing a gap.
class _StackStrip extends StatelessWidget {
  final WalletItem item;
  final String? badge;

  const _StackStrip({super.key, required this.item, this.badge});

  @override
  Widget build(BuildContext context) {
    final m = materialForItem(item);
    return Semantics(
      button: true,
      label: '${titleForItem(item)}, ${typeLabelFor(item.kind)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          openWalletItem(context, item);
        },
        child: SizedBox(
          height: _kStripHeight,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: _kStripHeight + 40,
            minHeight: _kStripHeight + 40,
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CwRadius.card),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x240E0F12),
                      blurRadius: 14,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: CardFace(
                  material: m,
                  shadow: false,
                  padding: kCardStripPadding,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: CardStripHeader(
                      item: item,
                      trailing: badge == null
                          ? null
                          : _StripBadge(text: badge!, fg: m.foreground),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripBadge extends StatelessWidget {
  final String text;
  final Color fg;
  const _StripBadge({required this.text, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: CwType.caption.copyWith(color: fg, fontSize: 11.5),
        ),
      );
}

/// The card at the front of the stack, shown in full with live tilt shine.
class _FrontCard extends StatelessWidget {
  final WalletItem item;
  const _FrontCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${titleForItem(item)}, ${typeLabelFor(item.kind)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          openWalletItem(context, item);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CwRadius.card),
            boxShadow: const [
              BoxShadow(
                color: Color(0x240E0F12),
                blurRadius: 14,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Hero(
            tag: item.heroTag,
            child: WalletCardFace(item: item, interactive: true),
          ),
        ),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Semantics(
      button: true,
      label: 'cwAddCard'.tr(),
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('homeAddFab'),
        color: c.brand,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: CwElevation.e2,
            ),
            alignment: Alignment.center,
            child: CwIcon(CwIcons.plus, size: CwIconSize.xl, color: c.onBrand),
          ),
        ),
      ),
    );
  }
}

/// First-run / zero-card home: one obvious action plus quick start rows.
class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final dash = c.ink.withValues(alpha: 0.13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              Positioned(
                left: 48,
                right: 48,
                top: 28,
                height: 170,
                child: _DashedCard(color: dash),
              ),
              Positioned(
                left: 64,
                right: 64,
                top: 52,
                height: 170,
                child: _DashedCard(color: dash.withValues(alpha: 0.09)),
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 92,
                height: 196,
                child: GestureDetector(
                  key: const ValueKey('homeEmptyAdd'),
                  onTap: () => openScanner(),
                  child: CardFace(
                    material: CardMaterial.of(11),
                    interactive: true,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CwIcon(CwIcons.plus,
                              size: 30, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            'cwEmptyTitle'.tr(),
                            textAlign: TextAlign.center,
                            style:
                                CwType.headline.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'cwEmptySub'.tr(),
                            textAlign: TextAlign.center,
                            style: CwType.footnote.copyWith(
                                color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        CwSectionHeader('cwQuickStart'.tr()),
        // What the user said they carry (onboarding) comes first.
        Obx(() {
          final carry = UiPrefs.instance.carry;
          final rows = <(String, Widget)>[
            (
              'loyalty',
              CwRow(
                leading: CwIconTile(CwIcons.barcode, color: c.ok),
                title: 'cwQsLoyalty'.tr(),
                subtitle: 'cwQsLoyaltySub'.tr(),
                chevron: true,
                onTap: () => openScanner(mode: ScanMode.barcode),
              ),
            ),
            (
              'cards',
              CwRow(
                leading: CwIconTile(CwIcons.card, color: c.ink),
                title: 'cwQsCard'.tr(),
                subtitle: 'cwQsCardSub'.tr(),
                chevron: true,
                onTap: () => openScanner(mode: ScanMode.card),
              ),
            ),
            (
              'iban',
              CwRow(
                leading:
                    CwIconTile(CwIcons.bank, color: const Color(0xFF2E6385)),
                title: 'cwQsIban'.tr(),
                subtitle: 'cwQsIbanSub'.tr(),
                chevron: true,
                onTap: () => openScanner(mode: ScanMode.iban),
              ),
            ),
          ];
          bool carried(String kind) =>
              carry.contains(kind) ||
              (kind == 'loyalty' && carry.contains('members'));
          return CwGroup(
            children: [
              for (final r in rows.where((r) => carried(r.$1))) r.$2,
              for (final r in rows.where((r) => !carried(r.$1))) r.$2,
              CwRow(
                leading: CwIconTile(CwIcons.import, color: c.warn),
                title: 'cwQsImport'.tr(),
                subtitle: 'cwQsImportSub'.tr(),
                chevron: true,
                onTap: () => openImport(context),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _DashedCard extends StatelessWidget {
  final Color color;
  const _DashedCard({required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DashPainter(color));
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(CwRadius.l),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 13;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
