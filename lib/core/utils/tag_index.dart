import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';

/// Special tag value that the home page (and the favorite button) treat
/// as "starred". Centralised so we don't sprinkle the literal across
/// the codebase.
const String kFavoriteTag = 'favorite';

/// Collect every distinct tag attached to any credit or IBAN card. Used
/// by the autocomplete suggestions and the filter chips so users see the
/// same tag pool everywhere instead of fragmenting on typos.
Set<String> collectAllTags({
  required Iterable<CreditCard> credits,
  required Iterable<IbanCard> ibans,
}) {
  final set = <String>{};
  for (final c in credits) {
    final tags = c.tags;
    if (tags == null) continue;
    for (final t in tags) {
      final trimmed = t.trim();
      if (trimmed.isNotEmpty) set.add(trimmed);
    }
  }
  for (final c in ibans) {
    final tags = c.tags;
    if (tags == null) continue;
    for (final t in tags) {
      final trimmed = t.trim();
      if (trimmed.isNotEmpty) set.add(trimmed);
    }
  }
  return set;
}

/// Toggles the favorite tag on any of the three card kinds in-place by
/// editing its `tags` list and persisting via the supplied saver. Returns
/// the new favorite state. Uses the model directly so HiveObject.save()
/// is enough — no need to round-trip through the service's update API.
bool toggleFavoriteTag(dynamic card) {
  if (card is CreditCard) {
    final tags = (card.tags ?? <String>[]).toList();
    final isFav = tags.contains(kFavoriteTag);
    if (isFav) {
      tags.remove(kFavoriteTag);
    } else {
      tags.add(kFavoriteTag);
    }
    card.tags = tags;
    card.save();
    return !isFav;
  }
  if (card is IbanCard) {
    final tags = (card.tags ?? <String>[]).toList();
    final isFav = tags.contains(kFavoriteTag);
    if (isFav) {
      tags.remove(kFavoriteTag);
    } else {
      tags.add(kFavoriteTag);
    }
    card.tags = tags;
    card.save();
    return !isFav;
  }
  if (card is LoyaltyCard) {
    final tags = (card.tags ?? <String>[]).toList();
    final isFav = tags.contains(kFavoriteTag);
    if (isFav) {
      tags.remove(kFavoriteTag);
    } else {
      tags.add(kFavoriteTag);
    }
    card.tags = tags;
    card.save();
    return !isFav;
  }
  return false;
}

/// True if [card]'s `tags` list contains [kFavoriteTag]. Works across
/// all three kinds.
bool isFavoriteCard(dynamic card) {
  List<String>? tags;
  if (card is CreditCard) tags = card.tags;
  if (card is IbanCard) tags = card.tags;
  if (card is LoyaltyCard) tags = card.tags;
  return tags?.contains(kFavoriteTag) ?? false;
}

/// Sorted list (case-insensitive) so chips and suggestion lists render
/// in a deterministic order.
List<String> sortedTags(Iterable<String> tags) {
  final list = tags.toList();
  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}
