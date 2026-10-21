import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/search_normalize.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';

/// Searchable text per card kind:
///  * credit: holder, bank, tags, last 4 digits
///  * IBAN: holder, bank, last 4 characters of the IBAN
///  * loyalty: name, brand, tags, notes
///
/// Only the last 4 of a card number / IBAN are searchable, so a typed full
/// number never matches (nor needs to sit in a search index).
List<String> walletSearchFields(WalletItem item) {
  switch (item.kind) {
    case WalletItemKind.credit:
      final c = item.card as CreditCard;
      return [
        c.cardHolder,
        c.bankName,
        ..._userTags(c.tags),
        last4(c.creditCardNumber),
      ];
    case WalletItemKind.iban:
      final c = item.card as IbanCard;
      return [c.cardHolder, c.bankName, last4(c.iban)];
    case WalletItemKind.loyalty:
      final c = item.card as LoyaltyCard;
      return [
        c.name,
        c.brand ?? '',
        ..._userTags(c.tags),
        c.notes ?? '',
      ];
  }
}

/// Last 4 letters/digits of a card number or IBAN, spaces stripped.
String last4(String raw) {
  final clean = raw.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  return clean.length <= 4 ? clean : clean.substring(clean.length - 4);
}

/// The favourite flag is stored as a tag; it isn't something users type.
Iterable<String> _userTags(List<String>? tags) =>
    (tags ?? const <String>[]).where((t) => t != kFavoriteTag);

/// [items] whose fields contain every word of [query], compared through
/// [normalizeForSearch] (Turkish- and accent-insensitive). Keeps the input
/// order (home's newest-first timeline). An empty query returns nothing.
List<WalletItem> searchWallet(Iterable<WalletItem> items, String query) {
  final tokens = normalizeForSearch(query)
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return const [];
  return items.where((item) {
    // \u0001 keeps a token from matching across two fields.
    final haystack = walletSearchFields(item)
        .where((f) => f.isNotEmpty)
        .map(normalizeForSearch)
        .join('\u0001');
    return tokens.every(haystack.contains);
  }).toList();
}
