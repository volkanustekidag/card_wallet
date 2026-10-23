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
import 'package:wallet_app/feature/home/widgets/home_order.dart';
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

  /// Tag the stack is narrowed to ([kFavoriteTag] = starred), or null.
  final ValueNotifier<String?> _folder = ValueNotifier(null);
  bool _pullArmed = true;

  HomeController get _c => widget.controller;

  @override
  void dispose() {
    _filter.dispose();
    _folder.dispose();
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
                  titleSize: 28,
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
                  final grid = UiPrefs.instance.homeGrid.value;
                  final sort = HomeSort.parse(UiPrefs.instance.homeSort.value);
                  final manual = UiPrefs.instance.manualOrder.toList();
                  if (items.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyWallet());
                  }
                  return ValueListenableBuilder<HomeFilter>(
                    valueListenable: _filter,
                    builder: (context, filter, _) =>
                        ValueListenableBuilder<String?>(
                      valueListenable: _folder,
                      builder: (context, folder, _) => _WalletSlivers(
                        controller: _c,
                        items: items,
                        showUpNext: showUpNext,
                        grid: grid,
                        filter: filter,
                        onFilter: (f) => _filter.value = f,
                        sort: sort,
                        manualOrder: manual,
                        folder: folder,
                        onFolder: (f) => _folder.value = f,
                      ),
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
  final bool grid;
  final HomeSort sort;
  final List<String> manualOrder;
  final String? folder;
  final ValueChanged<String?> onFolder;

  const _WalletSlivers({
    required this.controller,
    required this.items,
    required this.showUpNext,
    required this.grid,
    required this.filter,
    required this.onFilter,
    this.sort = HomeSort.smart,
    this.manualOrder = const [],
    this.folder,
    required this.onFolder,
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
    final folders = walletFolders(items);
    // A folder whose last card lost the tag is gone: show everything.
    final active = folders.contains(folder) ? folder : null;
    final stack = stackOrder(items, filter,
        sort: sort, manualOrder: manualOrder, folder: active);
    final upNext = showUpNext &&
            active == null &&
            (filter == HomeFilter.all || filter == HomeFilter.loyalty)
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
        if (folders.isNotEmpty)
          SliverToBoxAdapter(
            child: FolderRow(
              folders: folders,
              selected: active,
              onChanged: onFolder,
            ),
          ),
        if (upNext != null)
          SliverToBoxAdapter(
            child: _UpNextBanner(card: upNext.$1, reason: upNext.$2),
          ),
        SliverToBoxAdapter(
          child: _CountLine(
            count: stack.length,
            notice: notice,
            grid: grid,
            onGrid: stack.isEmpty
                ? null
                : (v) {
                    // Using the switch is the lesson; no hint needed after.
                    UiPrefs.instance.markViewHintSeen();
                    UiPrefs.instance.setHomeGrid(v);
                  },
            onSort: stack.length < 2
                ? null
                : () => showHomeSortSheet(context, items: items),
            // Once, the first time there's enough to show both ways.
            hintViews: stack.length >= 2,
          ),
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
        else if (grid)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: CwSpace.gutter),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: kCardAspect,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _GridCard(
                  key: ValueKey(stack[i].heroTag),
                  item: stack[i],
                  badge: _badgeFor(stack[i]),
                ),
                childCount: stack.length,
                addAutomaticKeepAlives: false,
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

/// Cards for a filter (and [folder]) in the order Home shows them.
///
/// [HomeSort.smart]: loyalty first (best guess for now on top), then IBANs,
/// then bank cards; favourites lead each kind, and the last card (shown in
/// full) is a bank card. [HomeSort.name]: A to Z. [HomeSort.manual]: the
/// user's [manualOrder] (hero tags), cards added since on top.
/// [folder] keeps cards with that tag ([kFavoriteTag] = starred ones).
List<WalletItem> stackOrder(
  List<WalletItem> items,
  HomeFilter filter, {
  HomeSort sort = HomeSort.smart,
  List<String> manualOrder = const [],
  String? folder,
}) {
  bool inFolder(WalletItem it) =>
      folder == null ||
      (folder == kFavoriteTag ? it.isFavorite : it.tags.contains(folder));
  final visible = [
    for (final it in items)
      if (filter.matches(it) && inFolder(it)) it,
  ];
  switch (sort) {
    case HomeSort.smart:
      return _smartOrder(visible);
    case HomeSort.name:
      final named = [
        for (final it in visible) (titleForItem(it).toLowerCase(), it),
      ]..sort((a, b) {
          final d = a.$1.compareTo(b.$1);
          return d != 0 ? d : a.$2.heroTag.compareTo(b.$2.heroTag);
        });
      return [for (final n in named) n.$2];
    case HomeSort.manual:
      final pos = {
        for (var i = 0; i < manualOrder.length; i++) manualOrder[i]: i,
      };
      final smart = _smartOrder(visible);
      final known = smart.where((it) => pos.containsKey(it.heroTag)).toList()
        ..sort((a, b) => pos[a.heroTag]!.compareTo(pos[b.heroTag]!));
      return [
        ...smart.where((it) => !pos.containsKey(it.heroTag)),
        ...known,
      ];
  }
}

/// User tags across [items], favourites first, for the folder row.
List<String> walletFolders(List<WalletItem> items) {
  final tags = <String>{};
  var favourites = false;
  for (final it in items) {
    if (it.isFavorite) favourites = true;
    tags.addAll(it.tags);
  }
  return [
    if (favourites) kFavoriteTag,
    ...sortedTags(tags),
  ];
}

List<WalletItem> _smartOrder(List<WalletItem> visible) {
  final loyalty = <LoyaltyCard>[];
  final ibans = <WalletItem>[];
  final credits = <WalletItem>[];
  for (final it in visible) {
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
  final bool grid;

  /// Switches stack / grid; null hides the switch (nothing to show).
  final ValueChanged<bool>? onGrid;

  /// Opens the order sheet; null hides the button.
  final VoidCallback? onSort;

  /// May show the one-time "stack or grid" tooltip under the switch.
  final bool hintViews;

  const _CountLine({
    required this.count,
    this.notice,
    this.grid = false,
    this.onGrid,
    this.onSort,
    this.hintViews = false,
  });

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
          if (right != null) right else const Spacer(),
          if (onSort != null) ...[
            const SizedBox(width: 10),
            SortButton(onTap: onSort!),
          ],
          if (onGrid != null) ...[
            const SizedBox(width: 10),
            Obx(() {
              // Read first: Obx needs the subscription even when hidden.
              final seen = UiPrefs.instance.viewHintSeen.value;
              return _ViewHintAnchor(
                show: hintViews && !seen,
                onDismiss: UiPrefs.instance.markViewHintSeen,
                child: _ViewSwitch(grid: grid, onChanged: onGrid!),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// One-time tooltip right under the stack / grid switch, floating above
/// everything (it never pushes the cards down). Tap it to dismiss.
class _ViewHintAnchor extends StatefulWidget {
  final bool show;
  final VoidCallback onDismiss;
  final Widget child;

  const _ViewHintAnchor({
    required this.show,
    required this.onDismiss,
    required this.child,
  });

  @override
  State<_ViewHintAnchor> createState() => _ViewHintAnchorState();
}

class _ViewHintAnchorState extends State<_ViewHintAnchor> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_ViewHintAnchor old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Show / hide after the frame: the overlay can't change mid-build.
  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.show && !_portal.isShowing) _portal.show();
      if (!widget.show && _portal.isShowing) _portal.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (_) => Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 6),
            child: GestureDetector(
              key: const ValueKey('homeViewHint'),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onDismiss();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    // Under the middle of the switch (68 wide).
                    padding: const EdgeInsets.only(right: 34 - 6),
                    child: CustomPaint(
                        size: const Size(12, 6), painter: _ArrowUp(c.ink)),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 210),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                    decoration: BoxDecoration(
                      color: c.ink,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: CwElevation.e2,
                    ),
                    child: Text(
                      'cwViewHintBody'.tr(),
                      style: CwType.footnote
                          .copyWith(color: c.bg, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _ArrowUp extends CustomPainter {
  final Color color;
  _ArrowUp(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowUp old) => old.color != color;
}

/// Two-icon switch between the stack and the grid.
class _ViewSwitch extends StatelessWidget {
  final bool grid;
  final ValueChanged<bool> onChanged;

  const _ViewSwitch({required this.grid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    Widget option(bool isGrid, CwIcons icon, String label) {
      final on = grid == isGrid;
      return Semantics(
        button: true,
        selected: on,
        label: label.tr(),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onChanged(isGrid);
                },
          child: AnimatedContainer(
            duration: CwMotion.fast,
            curve: CwMotion.standard,
            width: 32,
            height: 26,
            decoration: BoxDecoration(
              color: on ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              boxShadow: on
                  ? const [
                      BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 2,
                          offset: Offset(0, 1)),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: CwIcon(icon, size: 16, color: on ? c.ink : c.mute),
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('homeViewSwitch'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(false, CwIcons.stack, 'cwViewStack'),
          option(true, CwIcons.grid, 'cwViewGrid'),
        ],
      ),
    );
  }
}

/// A card in the Home grid. Presses in a touch, opens like a stack card.
class _GridCard extends StatefulWidget {
  final WalletItem item;
  final String? badge;

  const _GridCard({super.key, required this.item, this.badge});

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  bool _down = false;

  void _press(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Semantics(
      button: true,
      label: '${titleForItem(item)}, ${typeLabelFor(item.kind)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _press(true),
        onTapCancel: () => _press(false),
        onTapUp: (_) => _press(false),
        onTap: () {
          HapticFeedback.selectionClick();
          openWalletItem(context, item);
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: CwMotion.fast,
          curve: CwMotion.standard,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x240E0F12),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Hero(
              tag: item.heroTag,
              child: WalletMiniCard(item: item, badge: widget.badge),
            ),
          ),
        ),
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
