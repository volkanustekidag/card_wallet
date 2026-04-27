import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flip_card/flip_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/core/widgets/card_search_bar.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';

class Body extends StatefulWidget {
  final CreditCardController controller;

  const Body({super.key, required this.controller});

  @override
  State<Body> createState() => _BodyState();
}

enum _DemoStage { idle, flippingToBack, showingBack, flippingToFront }

class _BodyState extends State<Body> {
  static const _cardAspectRatio = 1.58;
  static const _itemAnimationDuration = Duration(milliseconds: 450);

  GlobalKey<FlipCardState>? _firstCardKey;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _demoShown = false;
  _DemoStage _demoStage = _DemoStage.idle;
  List<CreditCard> _cards = [];
  late final int _initialItemCount;
  Worker? _cardsWorker;
  String _searchQuery = '';
  CardSortOption _sortOption = CardSortOption.newest;

  @override
  void initState() {
    super.initState();
    _firstCardKey = GlobalKey<FlipCardState>();
    _cards = _filterAndSort(widget.controller.creditCards);
    _initialItemCount = _cards.length;
    _cardsWorker = ever<List<CreditCard>>(
        widget.controller.creditCards,
        (incoming) => _syncAnimatedList(_filterAndSort(incoming)));

    if (_cards.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleFlipDemo());
    }
  }

  @override
  void dispose() {
    _cardsWorker?.dispose();
    super.dispose();
  }

  void _resetDemoState() {
    _demoShown = false;
    _demoStage = _DemoStage.idle;
    _firstCardKey = GlobalKey<FlipCardState>();
  }

  void _scheduleFlipDemo() {
    if (_demoShown || _demoStage != _DemoStage.idle || _firstCardKey == null) {
      return;
    }
    _demoStage = _DemoStage.flippingToBack;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardState = _firstCardKey?.currentState;
      if (!_canAnimate(cardState)) {
        _demoStage = _DemoStage.idle;
        return;
      }

      if (!cardState!.isFront) {
        cardState.toggleCardWithoutAnimation();
      }

      Future.delayed(const Duration(milliseconds: _initialDelayMs), () {
        final state = _firstCardKey?.currentState;
        if (!_canAnimate(state) || _demoStage != _DemoStage.flippingToBack) {
          _demoStage = _DemoStage.idle;
          return;
        }
        state!.toggleCard();
      });
    });
  }

  bool _canAnimate(FlipCardState? cardState) {
    if (!mounted || cardState == null) return false;
    return cardState.mounted;
  }

  static const int _initialDelayMs = 400;
  static const int _backHoldDurationMs = 800;

  void _handleDemoFlip(bool wasFrontBeforeFlip) {
    if (_firstCardKey?.currentState == null) {
      _demoStage = _DemoStage.idle;
      return;
    }

    final showingBack = wasFrontBeforeFlip;

    if (_demoStage == _DemoStage.flippingToBack && showingBack) {
      _demoStage = _DemoStage.showingBack;
      Future.delayed(const Duration(milliseconds: _backHoldDurationMs), () {
        if (_demoStage != _DemoStage.showingBack) return;
        final state = _firstCardKey?.currentState;
        if (!_canAnimate(state)) {
          _demoStage = _DemoStage.idle;
          return;
        }
        _demoStage = _DemoStage.flippingToFront;
        state!.toggleCard();
      });
    } else if (_demoStage == _DemoStage.flippingToFront && !showingBack) {
      _demoStage = _DemoStage.idle;
      _demoShown = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _firstCardKey ??= GlobalKey<FlipCardState>();

    return Column(
      children: [
        Obx(() {
          if (widget.controller.creditCards.isEmpty) {
            return const SizedBox.shrink();
          }
          return CardSearchBar(
            query: _searchQuery,
            sort: _sortOption,
            onQueryChanged: (q) {
              setState(() => _searchQuery = q);
              _syncAnimatedList(
                  _filterAndSort(widget.controller.creditCards));
            },
            onSortChanged: (s) {
              setState(() => _sortOption = s);
              _syncAnimatedList(
                  _filterAndSort(widget.controller.creditCards));
            },
          );
        }),
        Expanded(
          child: Stack(
            children: [
              AnimatedList(
                key: _listKey,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                initialItemCount: _initialItemCount,
                itemBuilder: (context, index, animation) {
                  if (_cards.isEmpty || index >= _cards.length) {
                    return const SizedBox.shrink();
                  }
                  final creditCard = _cards[index];
                  final isFirstCard = index == 0;

                  return _buildAnimatedCard(
                    context: context,
                    creditCard: creditCard,
                    animation: animation,
                    highlight: isFirstCard,
                  );
                },
              ),
              if (widget.controller.creditCards.isEmpty)
                const Positioned.fill(
                  child: EmptyListInfo(
                    ctaRoute: '/addCreditCard',
                    ctaLabel: 'addFirstCC',
                    ctaIcon: Icons.credit_card,
                  ),
                )
              else if (_cards.isEmpty)
                _buildNoSearchResults(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoSearchResults() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'searchNoResults'.tr(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required BuildContext context,
    required CreditCard creditCard,
    required Animation<double> animation,
    required bool highlight,
    bool isRemoving = false,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: isRemoving ? Curves.easeInOut : Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, isRemoving ? 0 : 0.08),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AnimatedScale(
            scale: highlight ? 1.02 : 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: highlight ? 30 : 18,
                    spreadRadius: highlight ? 1 : 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => _showCardActionsSheet(creditCard),
                child: AspectRatio(
                  aspectRatio: _cardAspectRatio,
                  child: FlipCard(
                    key: highlight ? _firstCardKey : null,
                    direction: FlipDirection.HORIZONTAL,
                    speed: 1000,
                    onFlipDone: highlight ? _handleDemoFlip : null,
                    front: CreditCardFront(creditCard: creditCard),
                    back: CreditCardBack(creditCard: creditCard),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _syncAnimatedList(List<CreditCard> incomingCards) {
    if (!mounted) return;

    final sorted = _sortCards(incomingCards);

    if (_listKey.currentState == null) {
      _cards = sorted;
      if (_cards.isEmpty) {
        _resetDemoState();
      } else {
        _scheduleFlipDemo();
      }
      setState(() {});
      return;
    }

    final newIdSet = sorted.map((card) => card.id.toString()).toSet();

    for (int i = _cards.length - 1; i >= 0; i--) {
      final id = _cards[i].id.toString();
      if (!newIdSet.contains(id)) {
        final removedCard = _cards.removeAt(i);
        _listKey.currentState!.removeItem(
          i,
          (itemContext, animation) => _buildAnimatedCard(
            context: itemContext,
            creditCard: removedCard,
            animation: animation,
            highlight: i == 0,
            isRemoving: true,
          ),
          duration: _itemAnimationDuration,
        );
      }
    }

    for (int i = 0; i < sorted.length; i++) {
      final card = sorted[i];
      final existingIndex =
          _cards.indexWhere((element) => element.id == card.id);

      if (existingIndex == -1) {
        _cards.insert(i, card);
        _listKey.currentState!.insertItem(
          i,
          duration: _itemAnimationDuration,
        );
      } else {
        _cards[existingIndex] = card;
        if (existingIndex != i) {
          final movedCard = _cards.removeAt(existingIndex);
          _cards.insert(i, movedCard);
        }
      }
    }

    if (_cards.isEmpty) {
      _resetDemoState();
    } else {
      _scheduleFlipDemo();
    }

    setState(() {});
  }

  List<CreditCard> _filterAndSort(List<CreditCard> cards) {
    final filtered = _searchQuery.trim().isEmpty
        ? List<CreditCard>.from(cards)
        : cards.where((c) => _matchesQuery(c, _searchQuery)).toList();

    switch (_sortOption) {
      case CardSortOption.newest:
        filtered.sort((a, b) => compareNewestFirst(
              aCreatedAt: a.createdAt,
              aId: a.id,
              bCreatedAt: b.createdAt,
              bId: b.id,
            ));
        break;
      case CardSortOption.oldest:
        filtered.sort((a, b) => compareNewestFirst(
              aCreatedAt: b.createdAt,
              aId: b.id,
              bCreatedAt: a.createdAt,
              bId: a.id,
            ));
        break;
      case CardSortOption.nameAsc:
        filtered.sort(
            (a, b) => a.cardHolder.toLowerCase().compareTo(b.cardHolder.toLowerCase()));
        break;
      case CardSortOption.nameDesc:
        filtered.sort(
            (a, b) => b.cardHolder.toLowerCase().compareTo(a.cardHolder.toLowerCase()));
        break;
      case CardSortOption.bank:
        filtered.sort(
            (a, b) => a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase()));
        break;
    }
    return filtered;
  }

  bool _matchesQuery(CreditCard card, String query) {
    final q = query.toLowerCase();
    return card.bankName.toLowerCase().contains(q) ||
        card.cardHolder.toLowerCase().contains(q) ||
        card.creditCardNumber.replaceAll(' ', '').contains(q) ||
        (card.notes?.toLowerCase().contains(q) ?? false) ||
        (card.tags?.any((t) => t.toLowerCase().contains(q)) ?? false);
  }

  Future<void> _showCardActionsSheet(CreditCard creditCard) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'cardActions'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                _CardActionTile(
                  icon: Icons.copy_rounded,
                  label: 'copyCardNumberAction'.tr(),
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: creditCard.creditCardNumber),
                    );
                    HapticFeedback.lightImpact();
                    Navigator.of(sheetContext).pop();
                    context.showSuccessSnackBar('copyInfo');
                  },
                ),
                _CardActionTile(
                  icon: Icons.edit_rounded,
                  label: 'editCC'.tr(),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Get.to(
                      () => AddCreditCardPage(creditCard: creditCard),
                      binding: AddCreditCardBindings(),
                    )?.then((_) {
                      widget.controller.loadCreditCards();
                      _resetDemoState();
                    });
                  },
                ),
                _CardActionTile(
                  icon: Icons.delete_forever_rounded,
                  label: 'deleteCardAction'.tr(),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await showDialogDeleteData(
                      context,
                      () => widget.controller.removeCreditCard(creditCard),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showDialogDeleteData(
      BuildContext context, Future<void> Function() onConfirm) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: 'deleteCreditCard'.tr(),
          content: 'deleteDataMessage'.tr(),
          onConfirm: () async {
            await onConfirm();
            Get.back();
            _resetDemoState();
          },
        );
      },
    );
  }
}

class _CardActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foregroundColor;

  const _CardActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 0,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
      onTap: onTap,
    );
  }
}
