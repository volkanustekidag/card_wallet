import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/widgets/card_search_bar.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/loyalty_card_widget.dart';

class LoyaltyCardsPage extends StatefulWidget {
  const LoyaltyCardsPage({Key? key}) : super(key: key);

  @override
  State<LoyaltyCardsPage> createState() => _LoyaltyCardsPageState();
}

class _LoyaltyCardsPageState extends State<LoyaltyCardsPage> {
  late final LoyaltyCardController _controller;
  String _searchQuery = '';
  CardSortOption _sortOption = CardSortOption.newest;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LoyaltyCardController>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'loyaltyCardsTitle'.tr(),
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
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _handleAdd,
              child: Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const LoadingWidget();
        }
        if (_controller.loyaltyCards.isEmpty) {
          return EmptyListInfo(
            ctaLabel: 'addFirstLoyaltyCard',
            ctaIcon: Icons.local_offer,
            onCtaTap: _handleAdd,
          );
        }
        final filtered = _filterAndSort(_controller.loyaltyCards.toList());
        return Column(
          children: [
            CardSearchBar(
              query: _searchQuery,
              sort: _sortOption,
              onQueryChanged: (q) => setState(() => _searchQuery = q),
              onSortChanged: (s) => setState(() => _sortOption = s),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _buildNoSearchResults(context)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final card = filtered[index];
                        return LoyaltyCardWidget(
                          key: ValueKey(card.id),
                          card: card,
                          onTap: () => _openDetail(card),
                          onLongPress: () => _showActions(card),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  List<LoyaltyCard> _filterAndSort(List<LoyaltyCard> cards) {
    final filtered = _searchQuery.trim().isEmpty
        ? List<LoyaltyCard>.from(cards)
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
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case CardSortOption.nameDesc:
        filtered.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case CardSortOption.bank:
        filtered.sort((a, b) => (a.brand ?? '')
            .toLowerCase()
            .compareTo((b.brand ?? '').toLowerCase()));
        break;
    }
    return filtered;
  }

  bool _matchesQuery(LoyaltyCard card, String query) {
    final q = query.toLowerCase();
    return card.name.toLowerCase().contains(q) ||
        (card.brand?.toLowerCase().contains(q) ?? false) ||
        card.barcode.toLowerCase().contains(q) ||
        (card.notes?.toLowerCase().contains(q) ?? false);
  }

  Widget _buildNoSearchResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: colorScheme.onSurface.withValues(alpha: 0.4)),
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

  Future<void> _handleAdd() async {
    final premium = Get.find<PremiumController>();
    final count = await premium.getStoredCardCount(CardLimitType.loyalty);
    if (!premium.canAddMoreLoyaltyCards(count)) {
      final unlocked =
          await showCardLimitDialog(context, CardLimitType.loyalty);
      if (!unlocked) return;
    }
    Get.to(
      () => const AddLoyaltyCardPage(),
      binding: AddLoyaltyCardBindings(),
    )?.then((_) => _controller.loadLoyaltyCards());
  }

  void _openDetail(LoyaltyCard card) {
    Get.to(() => LoyaltyCardDetailPage(card: card))
        ?.then((_) => _controller.loadLoyaltyCards());
  }

  void _showActions(LoyaltyCard card) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_2_rounded),
                title: Text('showBarcodeAction'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openDetail(card);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text('copyBarcodeAction'.tr()),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: card.barcode));
                  HapticFeedback.lightImpact();
                  Navigator.pop(sheetContext);
                  context.showSuccessSnackBar('copyInfo');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text('editCard'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Get.to(
                    () => AddLoyaltyCardPage(card: card),
                    binding: AddLoyaltyCardBindings(),
                  )?.then((_) => _controller.loadLoyaltyCards());
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'deleteCard'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDialog<void>(
                    context: context,
                    builder: (_) => CustomDialog(
                      title: 'deleteCard'.tr(),
                      content: 'deleteDataMessage'.tr(),
                      onConfirm: () async {
                        await _controller.removeLoyaltyCard(card);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
