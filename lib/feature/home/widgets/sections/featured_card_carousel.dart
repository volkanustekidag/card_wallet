import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/feature/home/widgets/sections/featured_card_tile.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_animations.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';

/// Apple-Wallet-flavoured PageView. The center card is at full size and the
/// neighbours peek in at ~85% scale with a softer alpha. Caps at 6 items so
/// the viewport never gets dot-soup. Tapping a credit card flips it to
/// reveal the back. IBAN and loyalty cards are intentionally
/// non-interactive in the carousel — for the full preview the user goes
/// through the "Show" action below.
///
/// When [scrollOffset] is wired in, the active card tilts 0..6° on the
/// X axis as the page scrolls, mimicking a wallet card being closed.
class FeaturedCardCarousel extends StatefulWidget {
  final List<WalletItem> items;
  final ValueChanged<int>? onPageChanged;
  final int initialIndex;
  final ValueNotifier<double>? scrollOffset;

  const FeaturedCardCarousel({
    Key? key,
    required this.items,
    this.onPageChanged,
    this.initialIndex = 0,
    this.scrollOffset,
  }) : super(key: key);

  @override
  State<FeaturedCardCarousel> createState() => _FeaturedCardCarouselState();
}

class _FeaturedCardCarouselState extends State<FeaturedCardCarousel> {
  static const int _maxItems = 6;
  static const double _viewport = 0.72;
  late PageController _controller;
  // [_page] / [_isScrolling] used to live as setState-bound fields, which
  // means every page-controller scroll frame rebuilt the whole carousel
  // (PageView args, scroll-offset listenable, dots — all of it). They're
  // notifiers now: the items, the dots, and the scrolling guard each
  // listen to exactly the signal they need.
  late final ValueNotifier<double> _pageNotifier;
  final ValueNotifier<bool> _isScrollingNotifier = ValueNotifier(false);
  bool _scrollListenerAttached = false;

  List<WalletItem> get _items => widget.items.take(_maxItems).toList();

  @override
  void initState() {
    super.initState();
    final clamped = widget.initialIndex.clamp(0, _items.length - 1).toInt();
    _pageNotifier = ValueNotifier(clamped.toDouble());
    _controller = PageController(
      viewportFraction: _viewport,
      initialPage: clamped,
    );
    _controller.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final next = _controller.page ?? 0;
    // Fold sub-pixel ticks: PageController emits ~60 events per swipe and
    // we don't need to repaint the dots/items for a 0.001 delta.
    if ((_pageNotifier.value - next).abs() > 0.005) {
      _pageNotifier.value = next;
    }
    _ensureScrollListenerAttached();
  }

  void _ensureScrollListenerAttached() {
    if (_scrollListenerAttached) return;
    if (!_controller.hasClients) return;
    _controller.position.isScrollingNotifier.addListener(_onScrollingChanged);
    _scrollListenerAttached = true;
  }

  void _onScrollingChanged() {
    if (!mounted) return;
    final scrolling = _controller.hasClients &&
        _controller.position.isScrollingNotifier.value;
    if (scrolling == _isScrollingNotifier.value) return;
    _isScrollingNotifier.value = scrolling;
  }

  @override
  void didUpdateWidget(covariant FeaturedCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length && _items.isNotEmpty) {
      final current = _pageNotifier.value.round();
      final newIndex = current.clamp(0, _items.length - 1);
      if (newIndex != current) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.jumpToPage(newIndex);
        });
      }
    }
  }

  @override
  void dispose() {
    if (_scrollListenerAttached && _controller.hasClients) {
      _controller.position.isScrollingNotifier
          .removeListener(_onScrollingChanged);
    }
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    _pageNotifier.dispose();
    _isScrollingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final size = MediaQuery.of(context).size;
    final pageWidth = size.width * _viewport;
    final cardWidth = pageWidth - kCarouselItemGap * 2;
    final cardHeight = cardWidth / 1.586;
    final containerHeight = cardHeight + kCardShadowGutter;

    final pageView = PageView.builder(
      controller: _controller,
      physics: const PageScrollPhysics(),
      padEnds: true,
      itemCount: items.length,
      onPageChanged: (i) {
        HapticFeedback.selectionClick();
        widget.onPageChanged?.call(i);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return _CarouselSlot(
          item: item,
          index: index,
          pageNotifier: _pageNotifier,
          isScrollingNotifier: _isScrollingNotifier,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: containerHeight,
          child: widget.scrollOffset == null
              ? pageView
              : ValueListenableBuilder<double>(
                  valueListenable: widget.scrollOffset!,
                  builder: (context, value, child) {
                    // Tilt away once the user has scrolled past the carousel
                    // mid-line. 0 → 220 maps to 0..6° on X (downwards).
                    final t = (value / 220.0).clamp(0.0, 1.0);
                    final radians = 0.10 * t;
                    return Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0008)
                        ..rotateX(radians),
                      child: child,
                    );
                  },
                  child: pageView,
                ),
        ),
        _CarouselDots(count: items.length, pageNotifier: _pageNotifier),
      ],
    );
  }
}

/// One PageView cell. Subscribes to the page + isScrolling notifiers
/// itself so a swipe only rebuilds the visible cells (3 at a time on the
/// 0.72 viewport) and not the dots / scroll-offset wrapper.
class _CarouselSlot extends StatelessWidget {
  final WalletItem item;
  final int index;
  final ValueNotifier<double> pageNotifier;
  final ValueNotifier<bool> isScrollingNotifier;
  final double cardWidth;
  final double cardHeight;

  const _CarouselSlot({
    required this.item,
    required this.index,
    required this.pageNotifier,
    required this.isScrollingNotifier,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pageNotifier, isScrollingNotifier]),
      builder: (context, _) {
        final page = pageNotifier.value;
        final delta = (page - index).abs().clamp(0.0, 1.0);
        final scale = 1.03 - delta * 0.08;
        final opacity = 1.0 - delta * 0.25;
        // Flip is only enabled when the carousel is fully idle AND this
        // card is the focused one. While scrolling we render a plain
        // front face below — so even a stale flip animation can't be
        // visible mid-slide (no FlipCard in the tree to animate).
        final flipEnabled = delta < 0.05 && !isScrollingNotifier.value;
        return Align(
          alignment: const Alignment(0, -0.25),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kCarouselItemGap,
                ),
                child: Hero(
                  tag: item.heroTag,
                  createRectTween: (begin, end) =>
                      MaterialRectArcTween(begin: begin, end: end),
                  child: Material(
                    color: Colors.transparent,
                    child: _CarouselItem(
                      item: item,
                      width: cardWidth,
                      height: cardHeight,
                      flipEnabled: flipEnabled,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Per-kind carousel cell. Credit cards flip on tap (front ↔ back). IBAN
/// and loyalty cards are render-only here. Long-press triggers a peek
/// scale-up regardless of kind.
class _CarouselItem extends StatefulWidget {
  final WalletItem item;
  final double width;
  final double height;
  final bool flipEnabled;

  const _CarouselItem({
    required this.item,
    required this.width,
    required this.height,
    this.flipEnabled = true,
  });

  @override
  State<_CarouselItem> createState() => _CarouselItemState();
}

class _CarouselItemState extends State<_CarouselItem> {
  // Stable key so FlipCard's internal animation/orientation state survives
  // parent rebuilds during page swipes.
  final GlobalKey<FlipCardState> _flipKey = GlobalKey<FlipCardState>();

  // Tracks where the finger touched down so onTapUp can reject "taps" that
  // moved more than [_tapMovementSlop] pixels. Flutter's default tap slop
  // is 18 px — wide enough that a slow swipe registers as a tap and starts
  // a flip, which is exactly the "slide sırasında kart flip oluyor" symptom.
  // We tighten it so only an essentially-stationary press flips the card.
  static const double _tapMovementSlop = 8;
  Offset? _tapDownPosition;

  void _handleTapDown(TapDownDetails details) {
    _tapDownPosition = details.globalPosition;
  }

  void _handleTapUp(TapUpDetails details) {
    final start = _tapDownPosition;
    _tapDownPosition = null;
    if (start == null) return;
    if (!widget.flipEnabled) return;
    final movement = (details.globalPosition - start).distance;
    if (movement > _tapMovementSlop) return;
    HapticFeedback.selectionClick();
    _flipKey.currentState?.toggleCard();
  }

  void _handleTapCancel() {
    _tapDownPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (widget.item.kind == WalletItemKind.credit) {
      // The parent ClipRRect used to live here, wrapping the FlipCard at the
      // exact card rect. That clip shaved the apex frame of every flip — the
      // 3D rotation projects ~%15 past the static rect on each axis. Clip is
      // now pushed *into* CreditCardFront/CreditCardBack so each face rounds
      // its own corners, leaving the FlipCard rotation free to overshoot.
      //
      // Mid-slide we replace the FlipCard with a static front face. The
      // package's 3D rotation kept leaking a half-flipped frame whenever the
      // tree rebuilt during a swipe; pulling FlipCard out of the tree
      // entirely is the only way to guarantee the card never appears to flip
      // while the carousel is moving.
      final card = widget.item.card as CreditCard;
      body = Container(
        width: widget.width,
        height: widget.height,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: kCardShadow,
        ),
        child: widget.flipEnabled
            ? GestureDetector(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                child: FlipCard(
                  key: _flipKey,
                  direction: FlipDirection.HORIZONTAL,
                  speed: 600,
                  flipOnTouch: false,
                  front: CreditCardFront(creditCard: card, maskNumber: true),
                  back: CreditCardBack(creditCard: card),
                ),
              )
            : CreditCardFront(creditCard: card, maskNumber: true),
      );
    } else {
      body = FeaturedCardTile(
        item: widget.item,
        width: widget.width,
        height: widget.height,
      );
    }

    // Vertical breathing room around the card — flip overshoot now lands
    // here instead of being clipped at the card's rect.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.height * 0.10),
      child: LongPressPeek(
        peekScale: 1.06,
        onPeekStart: () => HapticFeedback.mediumImpact(),
        child: body,
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  final int count;
  final ValueNotifier<double> pageNotifier;
  const _CarouselDots({required this.count, required this.pageNotifier});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox(height: kCarouselDotSize);
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: kCarouselDotSize + 4,
      child: ValueListenableBuilder<double>(
        valueListenable: pageNotifier,
        builder: (context, page, _) {
          final activeIndex = page.round().clamp(0, count - 1);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final active = i == activeIndex;
              // Fractional distance from the active page — used to give
              // the dot adjacent to the swipe direction a small "stretch
              // toward" motion, like a magnetic morph.
              final relative = (page - i).abs();
              final stretch = (1.0 - relative.clamp(0.0, 1.0)) * 6.0;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: active ? 1 : 0),
                duration: const Duration(milliseconds: 360),
                curve: Curves.elasticOut,
                builder: (context, t, _) {
                  final width = kCarouselDotSize +
                      (kCarouselDotActiveWidth - kCarouselDotSize) * t +
                      stretch;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: width,
                    height: kCarouselDotSize,
                    decoration: BoxDecoration(
                      color: active
                          ? colorScheme.onSurface.withValues(alpha: 0.85)
                          : colorScheme.onSurface.withValues(
                              alpha:
                                  0.18 + 0.2 * (1 - relative).clamp(0.0, 1.0),
                            ),
                      borderRadius: BorderRadius.circular(kCarouselDotSize),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}
