import 'dart:math' as math;

import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/utils/tag_index.dart';

/// Marks one barcode display on [card]: bumps [LoyaltyCard.useCount] and
/// stamps [LoyaltyCard.lastUsedAt]. Caller persists.
void markLoyaltyUsed(LoyaltyCard card, DateTime now) {
  card.useCount = (card.useCount ?? 0) + 1;
  card.lastUsedAt = now;
  final log = [...?card.usageLog, now.millisecondsSinceEpoch];
  card.usageLog = log.length > kUsageLogCap
      ? log.sublist(log.length - kUsageLogCap)
      : log;
}

/// Default loyalty order: favourites first, then most used (useCount, ties
/// broken by most recent lastUsedAt), then newest. Cards never used sit
/// after used ones and keep the newest-first order among themselves.
int compareLoyaltyByUsage(LoyaltyCard a, LoyaltyCard b) {
  final favA = a.tags?.contains(kFavoriteTag) ?? false;
  final favB = b.tags?.contains(kFavoriteTag) ?? false;
  if (favA != favB) return favA ? -1 : 1;

  final countCmp = (b.useCount ?? 0).compareTo(a.useCount ?? 0);
  if (countCmp != 0) return countCmp;

  final lastA = a.lastUsedAt;
  final lastB = b.lastUsedAt;
  if (lastA != null || lastB != null) {
    if (lastA == null) return 1;
    if (lastB == null) return -1;
    final lastCmp = lastB.compareTo(lastA);
    if (lastCmp != 0) return lastCmp;
  }

  return compareNewestFirst(
    aCreatedAt: a.createdAt,
    aId: a.id,
    bCreatedAt: b.createdAt,
    bId: b.id,
  );
}

/// Copy of [cards] in [compareLoyaltyByUsage] order.
List<LoyaltyCard> sortLoyaltyByUsage(Iterable<LoyaltyCard> cards) =>
    cards.toList()..sort(compareLoyaltyByUsage);

/// How likely [card] is to be needed at [now], from its own history: each
/// past use counts more when it happened near this time of day, on the same
/// weekday and recently (21-day half-life). Cards with uses from before the
/// log existed fall back to their count and last use. Never-used cards: 0.
double upNextScore(LoyaltyCard card, DateTime now) {
  final log = card.usageLog;
  double score = 0;
  if (log != null && log.isNotEmpty) {
    final nowMin = now.hour * 60 + now.minute;
    for (final ms in log) {
      final t = DateTime.fromMillisecondsSinceEpoch(ms);
      final ageDays = now.difference(t).inMinutes / 1440.0;
      if (ageDays < 0) continue;
      final recency = math.pow(0.5, ageDays / 21).toDouble();
      var dMin = ((t.hour * 60 + t.minute) - nowMin).abs();
      if (dMin > 720) dMin = 1440 - dMin;
      final h = dMin / 60.0;
      final timeOfDay = math.exp(-(h * h) / (2 * 1.5 * 1.5));
      final weekday = t.weekday == now.weekday ? 1.0 : 0.35;
      score += recency * (0.25 + timeOfDay) * weekday;
    }
  } else if ((card.useCount ?? 0) > 0) {
    final last = card.lastUsedAt;
    final ageDays = last == null ? 60.0 : now.difference(last).inHours / 24.0;
    score = math.log(1 + card.useCount!) *
        math.pow(0.5, ageDays.clamp(0, 365) / 21).toDouble() *
        0.3;
  }
  if (card.tags?.contains(kFavoriteTag) ?? false) score += 0.05;
  return score;
}

/// Cards ordered for "Up Next": best guess for right now first. Ties and
/// unused cards keep the [compareLoyaltyByUsage] order.
List<LoyaltyCard> sortLoyaltyForNow(Iterable<LoyaltyCard> cards, DateTime now) {
  final scored = [for (final c in cards) (c, upNextScore(c, now))];
  scored.sort((a, b) {
    final cmp = b.$2.compareTo(a.$2);
    return cmp != 0 ? cmp : compareLoyaltyByUsage(a.$1, b.$1);
  });
  return [for (final e in scored) e.$1];
}
