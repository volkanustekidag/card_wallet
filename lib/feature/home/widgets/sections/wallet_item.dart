import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/utils/tag_index.dart';

/// Adapter that lets the home page treat CC, IBAN and loyalty cards as one
/// timeline. Lets the featured carousel and the recent-cards list iterate a
/// single sorted sequence without three branches in every render.
enum WalletItemKind { credit, iban, loyalty }

/// Drives the home page filter chip row. `all` is the no-op default;
/// `favorites` is orthogonal to the kinds — it ignores the kind axis and
/// keeps any starred card across all three kinds.
enum HomeFilter { all, credit, iban, loyalty, favorites }

extension HomeFilterX on HomeFilter {
  WalletItemKind? get kind {
    switch (this) {
      case HomeFilter.credit:
        return WalletItemKind.credit;
      case HomeFilter.iban:
        return WalletItemKind.iban;
      case HomeFilter.loyalty:
        return WalletItemKind.loyalty;
      case HomeFilter.all:
      case HomeFilter.favorites:
        return null;
    }
  }

  bool matches(WalletItem item) {
    switch (this) {
      case HomeFilter.all:
        return true;
      case HomeFilter.credit:
        return item.kind == WalletItemKind.credit;
      case HomeFilter.iban:
        return item.kind == WalletItemKind.iban;
      case HomeFilter.loyalty:
        return item.kind == WalletItemKind.loyalty;
      case HomeFilter.favorites:
        return item.isFavorite;
    }
  }
}

class WalletItem {
  final WalletItemKind kind;
  final dynamic card;
  WalletItem.credit(CreditCard c)
      : kind = WalletItemKind.credit,
        card = c;
  WalletItem.iban(IbanCard c)
      : kind = WalletItemKind.iban,
        card = c;
  WalletItem.loyalty(LoyaltyCard c)
      : kind = WalletItemKind.loyalty,
        card = c;

  String get id {
    switch (kind) {
      case WalletItemKind.credit:
        return (card as CreditCard).id.toString();
      case WalletItemKind.iban:
        return (card as IbanCard).id.toString();
      case WalletItemKind.loyalty:
        return (card as LoyaltyCard).id;
    }
  }

  DateTime? get createdAt {
    switch (kind) {
      case WalletItemKind.credit:
        return (card as CreditCard).createdAt;
      case WalletItemKind.iban:
        return (card as IbanCard).createdAt;
      case WalletItemKind.loyalty:
        return (card as LoyaltyCard).createdAt;
    }
  }

  String get heroTag => 'home-card-${kind.name}-$id';

  bool get isFavorite => isFavoriteCard(card);

  /// The user's own tags ("work", "family"); the favourite flag excluded.
  List<String> get tags {
    final raw = switch (kind) {
      WalletItemKind.credit => (card as CreditCard).tags,
      WalletItemKind.iban => (card as IbanCard).tags,
      WalletItemKind.loyalty => (card as LoyaltyCard).tags,
    };
    return [
      for (final t in raw ?? const <String>[])
        if (t.trim().isNotEmpty && t != kFavoriteTag) t.trim(),
    ];
  }
}

/// How Home orders the cards.
enum HomeSort {
  /// Up Next guess and favourites first, grouped by kind (the default).
  smart,

  /// Alphabetical by the name shown on the card.
  name,

  /// The user's own drag-and-drop order.
  manual;

  static HomeSort parse(String? s) =>
      HomeSort.values.firstWhere((v) => v.name == s, orElse: () => smart);
}

List<WalletItem> mergeAndSort({
  required List<CreditCard> credits,
  required List<IbanCard> ibans,
  required List<LoyaltyCard> loyalties,
}) {
  final all = <WalletItem>[
    ...credits.map(WalletItem.credit),
    ...ibans.map(WalletItem.iban),
    ...loyalties.map(WalletItem.loyalty),
  ];
  all.sort((a, b) => compareNewestFirst(
        aCreatedAt: a.createdAt,
        aId: a.id,
        bCreatedAt: b.createdAt,
        bId: b.id,
      ));
  return all;
}
