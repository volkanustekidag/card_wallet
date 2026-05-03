import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_action_row.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_filter_chips.dart';
import 'package:wallet_app/feature/home/widgets/sections/featured_card_carousel.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_header.dart';
import 'package:wallet_app/feature/home/widgets/sections/premium_status_strip.dart';
import 'package:wallet_app/feature/home/widgets/sections/quick_actions_grid.dart';
import 'package:wallet_app/feature/home/widgets/sections/recent_cards_list.dart';
import 'package:wallet_app/feature/home/widgets/sections/smart_suggestion_card.dart';
import 'package:wallet_app/feature/home/widgets/sections/upcoming_card_notices.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sections/welcome_stack.dart';

/// New home body — column-based, no SliverAppBar. Order:
/// header → featured carousel → action row → 2x2 quick actions →
/// filter chips → recent cards. Empty wallet swaps the carousel/action
/// panel for a WelcomeStack.
///
/// Performance discipline:
///   * The CustomScrollView shell never rebuilds on scroll, carousel
///     swipes, or filter chip taps. Only the leaf widgets that actually
///     care subscribe to those signals via [ValueListenableBuilder] /
///     [Obx] inside themselves.
///   * The wallet timeline is computed once in the controller — no
///     mergeAndSort() calls on the build path.
///   * Scroll offsets are coalesced to ~2px so we don't fan out 60+
///     rebuilds across three children for sub-pixel deltas.
class HomeBody extends StatefulWidget {
  final HomeController controller;
  const HomeBody({Key? key, required this.controller}) : super(key: key);

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final ValueNotifier<HomeFilter> _filter = ValueNotifier(HomeFilter.all);
  final ValueNotifier<int> _carouselIndex = ValueNotifier(0);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);
  // Quantize offset emissions: only push when we've drifted at least 2px
  // since the last emission. ValueListenableBuilder will short-circuit on
  // value equality, so this collapses 60-pixel scroll runs into ~30
  // rebuilds per child instead of 60.
  static const double _scrollEmitThreshold = 2.0;
  double _lastEmittedOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final next = _scrollController.offset;
    if ((next - _lastEmittedOffset).abs() < _scrollEmitThreshold) return;
    _lastEmittedOffset = next;
    _scrollOffset.value = next;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    _filter.dispose();
    _carouselIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: _PullToRevealStats(
              offset: _scrollOffset,
              controller: widget.controller,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: HomeHeader(
            controller: widget.controller,
            scrollOffset: _scrollOffset,
          ),
        ),
        // The carousel / welcome stack and the action row both depend on
        // the wallet item list. Wrap *only* this slice in Obx so a card
        // add/delete only retargets these two slivers — the rest of the
        // tree (header, premium strip, quick actions, etc.) stays put.
        SliverToBoxAdapter(
          child: Obx(() {
            final items = widget.controller.walletItems;
            if (items.isEmpty) {
              return const WelcomeStack();
            }
            return FeaturedCardCarousel(
              items: items,
              onPageChanged: (i) => _carouselIndex.value = i,
              scrollOffset: _scrollOffset,
            );
          }),
        ),
        SliverToBoxAdapter(
          child: Obx(() {
            final items = widget.controller.walletItems;
            if (items.isEmpty) return const SizedBox.shrink();
            return ValueListenableBuilder<int>(
              valueListenable: _carouselIndex,
              builder: (context, idx, _) {
                final activeItem = items[idx.clamp(0, items.length - 1)];
                return CardActionRow(activeItem: activeItem);
              },
            );
          }),
        ),
        SliverToBoxAdapter(
          child: PremiumStatusStrip(controller: widget.controller),
        ),
        SliverToBoxAdapter(
          child: QuickActionsGrid(controller: widget.controller),
        ),
        SliverToBoxAdapter(
          child: UpcomingCardNotices(controller: widget.controller),
        ),
        SliverToBoxAdapter(
          child: Obx(() {
            final items = widget.controller.walletItems;
            if (items.isEmpty) return const SizedBox.shrink();
            return ValueListenableBuilder<HomeFilter>(
              valueListenable: _filter,
              builder: (context, filter, _) {
                return CardFilterChips(
                  selected: filter,
                  onChanged: (f) => _filter.value = f,
                  scrollOffset: _scrollOffset,
                );
              },
            );
          }),
        ),
        SliverToBoxAdapter(
          child: Obx(() {
            final items = widget.controller.walletItems;
            if (items.isEmpty) return const SizedBox.shrink();
            return ValueListenableBuilder<HomeFilter>(
              valueListenable: _filter,
              builder: (context, filter, _) {
                return RecentCardsList(
                  items: items,
                  activeFilter: filter,
                  scrollOffset: _scrollOffset,
                );
              },
            );
          }),
        ),
        SliverToBoxAdapter(
          child: SmartSuggestionCard(controller: widget.controller),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: kSpaceXXL),
        ),
      ],
    );
  }
}

/// Sits at the very top of the scroll view. Visible only when the user
/// over-pulls (BouncingScrollPhysics gives us negative offsets), counts
/// up a tiny "X cards · Y banks" hint. No real refresh — just a wallet
/// summary peek that rewards the gesture.
class _PullToRevealStats extends StatelessWidget {
  final ValueNotifier<double> offset;
  final HomeController controller;

  const _PullToRevealStats({required this.offset, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, value, _) {
        // Negative offset = over-pull. Reveal kicks in after 8px.
        final pull = (-value - 8).clamp(0.0, 60.0);
        final t = pull / 60.0;
        if (t <= 0) return const SizedBox.shrink();
        // Computing card/bank counts is cheap (loop over items, hit a
        // Set), but we only do it when the pull has actually started so
        // the cold scroll path stays free. Reading walletItems here
        // doesn't subscribe (we're not inside Obx) — that's fine because
        // we re-read every time the user over-pulls anyway.
        final items = controller.walletItems;
        if (items.isEmpty) return const SizedBox.shrink();
        final cardCount = items.length;
        final bankNames = <String>{};
        for (final w in items) {
          switch (w.kind) {
            case WalletItemKind.credit:
            case WalletItemKind.iban:
              final bank = (w.card as dynamic).bankName as String?;
              if (bank != null && bank.isNotEmpty) bankNames.add(bank);
              break;
            case WalletItemKind.loyalty:
              break;
          }
        }
        final bankCount = bankNames.length;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Container(
            height: 24 + 16 * t,
            alignment: Alignment.center,
            child: Text(
              'walletStatsHint'.tr(
                namedArgs: {
                  'cards': '$cardCount',
                  'banks': '$bankCount',
                },
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        );
      },
    );
  }
}
