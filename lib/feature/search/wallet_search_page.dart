import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/recent_cards_list.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sheets/card_detail_sheet.dart';
import 'package:wallet_app/feature/search/wallet_search.dart';

/// Opens the wallet-wide search from the home header.
Future<void> openWalletSearch() => Get.to<void>(
      () => const WalletSearchPage(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 180),
    ) ??
    Future.value();

/// Search across credit, IBAN and loyalty cards (see [searchWallet]).
/// Tapping a result opens the same detail sheet as the home list.
///
/// Logs one `search_used {results_count, selected_type}` per visit: on the
/// first opened result, or on leaving with a query but no pick. The query
/// itself never leaves this widget.
class WalletSearchPage extends StatefulWidget {
  const WalletSearchPage({Key? key}) : super(key: key);

  @override
  State<WalletSearchPage> createState() => _WalletSearchPageState();
}

class _WalletSearchPageState extends State<WalletSearchPage> {
  final TextEditingController _query = TextEditingController();
  int _lastResultsCount = 0;
  bool _logged = false;

  @override
  void dispose() {
    if (!_logged && _query.text.trim().isNotEmpty) {
      _logSearch('none');
    }
    _query.dispose();
    super.dispose();
  }

  void _logSearch(String selectedType) {
    _logged = true;
    AnalyticsService.instance.logSearchUsed(
      resultsCount: _lastResultsCount,
      selectedType: selectedType,
    );
  }

  void _open(WalletItem item) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    if (!_logged) _logSearch(_analyticsType(item.kind));
    showCardDetailSheet(context, item);
  }

  static String _analyticsType(WalletItemKind kind) {
    switch (kind) {
      case WalletItemKind.credit:
        return AnalyticsCardType.credit;
      case WalletItemKind.iban:
        return AnalyticsCardType.iban;
      case WalletItemKind.loyalty:
        return AnalyticsCardType.loyalty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            key: const ValueKey('walletSearchField'),
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'globalSearchHint'.tr(),
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'globalSearchClear'.tr(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(_query.clear),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        // Read the Rx first: Obx needs a subscription even while idle, and
        // results follow edits/deletes made from the detail sheet.
        final items = controller.walletItems.toList();
        final query = _query.text;
        if (query.trim().isEmpty) {
          return const EmptyListInfo(
            icon: Icons.manage_search_rounded,
            titleKey: 'globalSearchIdleTitle',
            subtitleKey: 'globalSearchIdleHint',
          );
        }
        final results = searchWallet(items, query);
        _lastResultsCount = results.length;
        if (results.isEmpty) {
          return const EmptyListInfo(
            icon: Icons.search_off_rounded,
            titleKey: 'searchNoResults',
            subtitleKey: 'globalSearchNoResultsHint',
          );
        }
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ResultTile(
            key: ValueKey(results[i].heroTag),
            item: results[i],
            onTap: () => _open(results[i]),
          ),
        );
      }),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final WalletItem item;
  final VoidCallback onTap;
  const _ResultTile({Key? key, required this.item, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (title, subtitle, kindLabel) = _texts();
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              WalletItemBadge(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                kindLabel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, String, String) _texts() {
    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        return (
          c.bankName.isNotEmpty ? c.bankName : 'creditCardLabel'.tr(),
          _join(c.cardHolder, '•••• ${last4(c.creditCardNumber)}'),
          'filterCredit'.tr(),
        );
      case WalletItemKind.iban:
        final c = item.card as IbanCard;
        return (
          c.bankName.isNotEmpty ? c.bankName : 'IBAN',
          _join(c.cardHolder, '•••• ${last4(c.iban)}'),
          'filterIban'.tr(),
        );
      case WalletItemKind.loyalty:
        final c = item.card as LoyaltyCard;
        final brand = c.brand ?? '';
        return (
          c.name.isNotEmpty ? c.name : brand,
          brand.isNotEmpty && brand != c.name
              ? brand
              : 'loyaltyCardLabel'.tr(),
          'filterLoyalty'.tr(),
        );
    }
  }

  static String _join(String a, String b) => a.isEmpty ? b : '$a · $b';
}
