/// Centralised sort helpers so credit cards and IBAN cards order by
/// the most recently added first. Falls back to numeric id parsing for
/// legacy rows that predate the `createdAt` field.
library;

DateTime _legacyTimestamp(dynamic id) {
  // ID format used since v1.x is `${millisecondsSinceEpoch}${4-digit suffix}`
  // — slice the leading 13 digits as the epoch when available.
  final raw = id?.toString() ?? '';
  if (raw.length >= 13) {
    final ms = int.tryParse(raw.substring(0, 13));
    if (ms != null && ms > 0) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }
  final parsed = int.tryParse(raw);
  if (parsed != null && parsed > 0) {
    return DateTime.fromMillisecondsSinceEpoch(parsed);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime cardEffectiveTimestamp(DateTime? createdAt, dynamic id) {
  return createdAt ?? _legacyTimestamp(id);
}

int compareNewestFirst({
  required DateTime? aCreatedAt,
  required dynamic aId,
  required DateTime? bCreatedAt,
  required dynamic bId,
}) {
  final a = cardEffectiveTimestamp(aCreatedAt, aId);
  final b = cardEffectiveTimestamp(bCreatedAt, bId);
  return b.compareTo(a);
}
