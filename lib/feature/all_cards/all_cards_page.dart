import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/widgets/card_search_bar.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/widgets/mini_iban_card_widget.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_filter_chips.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sheets/card_detail_sheet.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/loyalty_card_widget.dart';

/// Unified browser for every card the user owns. Backed by HomeController's
/// pre-merged walletItems timeline; segmented chips switch the [HomeFilter],
/// search and sort apply across all kinds. Tapping any card opens the
/// shared detail sheet — the same surface used from home and recent list.
class AllCardsPage extends StatefulWidget {
  const AllCardsPage({Key? key}) : super(key: key);

  @override
  State<AllCardsPage> createState() => _AllCardsPageState();
}

class _AllCardsPageState extends State<AllCardsPage> {
  static const _cardAspectRatio = 1.58;

  late HomeFilter _filter;
  String _searchQuery = '';
  CardSortOption _sortOption = CardSortOption.newest;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['filter'] is HomeFilter) {
      _filter = args['filter'] as HomeFilter;
    } else {
      _filter = HomeFilter.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'allCardsTitle'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Obx(() {
        final all = controller.walletItems;
        if (all.isEmpty) {
          return EmptyListInfo(
            ctaLabel: 'addFirstCard',
            ctaIcon: Icons.add_card_rounded,
            onCtaTap: () => showAddCardTypeSheet(context),
          );
        }
        final filtered = _applyFilters(all);
        return Column(
          children: [
            CardFilterChips(
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            CardSearchBar(
              query: _searchQuery,
              sort: _sortOption,
              onQueryChanged: (q) => setState(() => _searchQuery = q),
              onSortChanged: (s) => setState(() => _sortOption = s),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _buildNoMatch()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 32),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _itemTile(filtered[i]),
                    ),
            ),
          ],
        );
      }),
    );
  }

  List<WalletItem> _applyFilters(List<WalletItem> items) {
    Iterable<WalletItem> work = items.where(_filter.matches);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      work = work.where((it) => _matchesQuery(it, q));
    }
    final list = work.toList();
    list.sort(_comparator);
    return list;
  }

  bool _matchesQuery(WalletItem it, String q) {
    switch (it.kind) {
      case WalletItemKind.credit:
        final c = it.card as CreditCard;
        return c.bankName.toLowerCase().contains(q) ||
            c.cardHolder.toLowerCase().contains(q) ||
            c.creditCardNumber.replaceAll(' ', '').contains(q) ||
            (c.notes?.toLowerCase().contains(q) ?? false) ||
            (c.tags?.any((t) => t.toLowerCase().contains(q)) ?? false);
      case WalletItemKind.iban:
        final c = it.card as IbanCard;
        return c.bankName.toLowerCase().contains(q) ||
            c.cardHolder.toLowerCase().contains(q) ||
            c.iban.toLowerCase().replaceAll(' ', '').contains(q) ||
            (c.notes?.toLowerCase().contains(q) ?? false) ||
            (c.tags?.any((t) => t.toLowerCase().contains(q)) ?? false);
      case WalletItemKind.loyalty:
        final c = it.card as LoyaltyCard;
        return c.name.toLowerCase().contains(q) ||
            (c.brand?.toLowerCase().contains(q) ?? false) ||
            c.barcode.toLowerCase().contains(q) ||
            (c.notes?.toLowerCase().contains(q) ?? false);
    }
  }

  int _comparator(WalletItem a, WalletItem b) {
    switch (_sortOption) {
      case CardSortOption.newest:
        return compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        );
      case CardSortOption.oldest:
        return compareNewestFirst(
          aCreatedAt: b.createdAt,
          aId: b.id,
          bCreatedAt: a.createdAt,
          bId: a.id,
        );
      case CardSortOption.nameAsc:
        return _displayName(a).toLowerCase().compareTo(
              _displayName(b).toLowerCase(),
            );
      case CardSortOption.nameDesc:
        return _displayName(b).toLowerCase().compareTo(
              _displayName(a).toLowerCase(),
            );
      case CardSortOption.bank:
        return _bankOrBrand(a).toLowerCase().compareTo(
              _bankOrBrand(b).toLowerCase(),
            );
    }
  }

  String _displayName(WalletItem it) {
    switch (it.kind) {
      case WalletItemKind.credit:
        return (it.card as CreditCard).cardHolder;
      case WalletItemKind.iban:
        return (it.card as IbanCard).cardHolder;
      case WalletItemKind.loyalty:
        return (it.card as LoyaltyCard).name;
    }
  }

  String _bankOrBrand(WalletItem it) {
    switch (it.kind) {
      case WalletItemKind.credit:
        return (it.card as CreditCard).bankName;
      case WalletItemKind.iban:
        return (it.card as IbanCard).bankName;
      case WalletItemKind.loyalty:
        final c = it.card as LoyaltyCard;
        return c.brand ?? c.name;
    }
  }

  void _openDetail(WalletItem item) {
    HapticFeedback.selectionClick();
    showCardDetailSheet(context, item);
  }

  Widget _itemTile(WalletItem it) {
    switch (it.kind) {
      case WalletItemKind.credit:
        return _creditTile(it);
      case WalletItemKind.iban:
        final c = it.card as IbanCard;
        return MiniIbanCardWidget(
          key: ValueKey('iban-${c.id}'),
          ibanCard: c,
          onTap: () => _openDetail(it),
          onLongPress: () => _openDetail(it),
        );
      case WalletItemKind.loyalty:
        final c = it.card as LoyaltyCard;
        return LoyaltyCardWidget(
          key: ValueKey('loyalty-${c.id}'),
          card: c,
          onTap: () => _openDetail(it),
          onLongPress: () => _openDetail(it),
        );
    }
  }

  Widget _creditTile(WalletItem it) {
    final card = it.card as CreditCard;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDetail(it),
        child: AspectRatio(
          aspectRatio: _cardAspectRatio,
          child: CreditCardFront(creditCard: card, maskNumber: true),
        ),
      ),
    );
  }

  Widget _buildNoMatch() {
    final searchActive = _searchQuery.trim().isNotEmpty;
    // When the user hasn't typed a query, the only thing that could have
    // emptied the list is the segmented type chip — but from their POV
    // that's "I navigated to credit cards", not "I applied a filter".
    // Map each type to the proper "no cards of this type yet" view with
    // an Add CTA, matching what the dedicated list pages show.
    if (!searchActive) {
      switch (_filter) {
        case HomeFilter.credit:
          return const EmptyListInfo(
            ctaRoute: '/addCreditCard',
            ctaLabel: 'addFirstCC',
            ctaIcon: Icons.credit_card,
          );
        case HomeFilter.iban:
          return const EmptyListInfo(
            ctaRoute: '/addIbanCard',
            ctaLabel: 'addFirstIC',
            ctaIcon: Icons.account_balance,
          );
        case HomeFilter.loyalty:
          return const EmptyListInfo(
            ctaRoute: '/addLoyaltyCard',
            ctaLabel: 'addFirstLoyaltyCard',
            ctaIcon: Icons.local_offer,
          );
        case HomeFilter.favorites:
          return const EmptyListInfo(
            icon: Icons.star_outline_rounded,
            titleKey: 'noFavoritesYet',
          );
        case HomeFilter.all:
          // 'all' with no search means the wallet really is empty — but
          // the upper `all.isEmpty` branch should already have caught
          // this. Defensive fallback to the standard empty view.
          return const EmptyListInfo();
      }
    }
    return EmptyListInfo(
      icon: Icons.search_off_rounded,
      titleKey: 'searchNoResults',
      subtitleKey: 'searchNoResultsHint',
    );
  }
}
