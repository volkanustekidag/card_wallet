/// Returns the localization key for the greeting that suits [hour].
/// Centralised so both the hero header and any future banner use the same
/// boundaries (5–11 morning, 12–17 afternoon, 18–4 evening).
String greetingKeyForHour(int hour) {
  if (hour >= 5 && hour < 12) return 'goodMorning';
  if (hour >= 12 && hour < 18) return 'goodAfternoon';
  return 'goodEvening';
}

/// Compact integer formatter used in count badges. Keeps things readable
/// once a power user piles up hundreds of loyalty cards (we cap at "99+").
String compactCount(int n) {
  if (n < 0) return '0';
  if (n > 99) return '99+';
  return n.toString();
}
