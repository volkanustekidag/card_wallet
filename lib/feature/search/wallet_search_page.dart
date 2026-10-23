import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/loyalty_usage.dart';
import 'package:wallet_app/core/utils/search_normalize.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/search/wallet_search.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/navigation/open_wallet_item.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Opens the wallet-wide search (home header button, pull-down on home).
Future<void> openWalletSearch() =>
    Get.to<void>(
      () => const WalletSearchPage(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 180),
    ) ??
    Future.value();

/// Search across credit, IBAN and loyalty cards (see [searchWallet]).
/// Empty query shows suggestions (Up Next, favourites, recently used); a
/// result opens the card directly — loyalty straight to Checkout.
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
    if (!_logged && _query.text.trim().isNotEmpty) {
      _logSearch(_analyticsType(item.kind));
    }
    openWalletItem(context, item);
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
    final c = CwColors.of(context);
    final controller = Get.find<HomeController>();

    return CwPageStyle(
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                        child: _SearchField(
                            controller: _query,
                            onChanged: () => setState(() {}))),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'cwCancel'.tr(),
                        style: CwType.callout.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  // Read the Rx first: Obx needs a subscription even while
                  // idle, and results follow edits made from a detail page.
                  final items = controller.walletItems.toList();
                  final query = _query.text;
                  if (query.trim().isEmpty) {
                    final suggested = _suggestions(items);
                    if (suggested.isEmpty) return const SizedBox.shrink();
                    return _list(context, 'cwSuggested'.tr(), suggested, '');
                  }
                  final results = searchWallet(items, query);
                  _lastResultsCount = results.length;
                  if (results.isEmpty) {
                    return Align(
                      alignment: const Alignment(0, -0.4),
                      child: CwEmptyState(
                        icon: CwIcons.search,
                        title: 'cwNoResults'.tr(),
                        message: 'cwNoResultsHint'.tr(),
                      ),
                    );
                  }
                  return _list(context, 'cwResults'.tr(), results, query);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Up Next first, then favourites and recently used cards.
  List<WalletItem> _suggestions(List<WalletItem> items) {
    final now = DateTime.now();
    final loyalty = [
      for (final i in items)
        if (i.kind == WalletItemKind.loyalty) i.card as LoyaltyCard,
    ];
    final out = <WalletItem>[];
    final seen = <String>{};
    void add(WalletItem w) {
      if (seen.add(w.heroTag)) out.add(w);
    }

    for (final l in sortLoyaltyForNow(loyalty, now).take(3)) {
      add(WalletItem.loyalty(l));
    }
    for (final w in items.where((w) => w.isFavorite)) {
      add(w);
    }
    for (final w in items) {
      if (out.length >= 6) break;
      add(w);
    }
    return out.take(6).toList();
  }

  Widget _list(
    BuildContext context,
    String header,
    List<WalletItem> items,
    String query,
  ) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        CwSectionHeader(header),
        CwGroup(
          children: [
            for (final item in items)
              _ResultRow(
                key: ValueKey(item.heroTag),
                item: item,
                query: query,
                onTap: () => _open(item),
              ),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          CwIcon(CwIcons.search, size: 18, color: c.mute),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('walletSearchField'),
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => onChanged(),
              cursorColor: c.accent,
              style: CwType.body.copyWith(color: c.ink),
              decoration: InputDecoration(
                hintText: 'cwSearchHint'.tr(),
                hintStyle: CwType.body.copyWith(color: c.mute),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'globalSearchClear'.tr(),
              onPressed: () {
                controller.clear();
                onChanged();
              },
              icon: CwIcon(CwIcons.close, size: 16, color: c.mute),
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final WalletItem item;
  final String query;
  final VoidCallback onTap;

  const _ResultRow({
    super.key,
    required this.item,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final title = titleForItem(item);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CardThumb(item: item, width: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Highlighted(
                    text: title,
                    query: query,
                    style: CwType.callout
                        .copyWith(color: c.ink, fontWeight: FontWeight.w600),
                    highlight: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CwType.footnote.copyWith(color: c.mute),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.kind == WalletItemKind.loyalty)
              CwPill(
                'cwShow'.tr(),
                background: c.ink,
                foreground: c.bg,
              )
            else
              CwIcon(CwIcons.chevronRight, size: 18, color: c.mute),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    final type = typeLabelFor(item.kind);
    switch (item.kind) {
      case WalletItemKind.credit:
        final card = item.card as CreditCard;
        return '$type · •• ${last4(card.creditCardNumber)}';
      case WalletItemKind.iban:
        final card = item.card as IbanCard;
        return '$type · •• ${last4(card.iban)}';
      case WalletItemKind.loyalty:
        final card = item.card as LoyaltyCard;
        if (item.isFavorite) return '$type · ${'cwFavourite'.tr()}';
        final uses = card.useCount ?? 0;
        return uses > 0 ? '$type · ${'cwUsedTimes'.plural(uses)}' : type;
    }
  }
}

/// Title with the matched query tokens tinted. Falls back to plain text
/// when normalisation changes the length (so indices wouldn't line up).
class _Highlighted extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlight;

  const _Highlighted({
    required this.text,
    required this.query,
    required this.style,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final norm = normalizeForSearch(text);
    final tokens =
        normalizeForSearch(query).split(' ').where((t) => t.isNotEmpty);
    if (query.trim().isEmpty || norm.length != text.length) {
      return Text(text,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    final marks = List<bool>.filled(text.length, false);
    for (final t in tokens) {
      var i = norm.indexOf(t);
      while (i >= 0) {
        for (var k = i; k < i + t.length; k++) {
          marks[k] = true;
        }
        i = norm.indexOf(t, i + t.length);
      }
    }
    final spans = <TextSpan>[];
    var start = 0;
    for (var i = 1; i <= text.length; i++) {
      if (i == text.length || marks[i] != marks[start]) {
        spans.add(TextSpan(
          text: text.substring(start, i),
          style: marks[start] ? highlight : null,
        ));
        start = i;
      }
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
