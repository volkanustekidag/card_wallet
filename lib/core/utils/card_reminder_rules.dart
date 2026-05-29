import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';

class CardReminderRules {
  static const int expiryWidgetLookaheadDays = 60;
  static const int paymentWidgetLookaheadDays = 7;
  static const int paymentScheduleSlots = 12;

  static DateTime? parseExpiryDate(String value) {
    final match =
        RegExp(r'^\s*(\d{1,2})\s*/\s*(\d{2}|\d{4})\s*$').firstMatch(value);
    if (match == null) return null;

    final month = int.tryParse(match.group(1)!);
    var year = int.tryParse(match.group(2)!);
    if (month == null || year == null || month < 1 || month > 12) {
      return null;
    }
    if (year < 100) year += 2000;
    return DateTime(year, month + 1, 0);
  }

  static DateTime? expiryReminderDate(CreditCard card) {
    final expiryDate = parseExpiryDate(card.expirationDate);
    if (expiryDate == null) return null;
    return DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      safeHour(card.reminderHour),
    ).subtract(Duration(days: safeDaysBefore(card.expiryReminderDaysBefore)));
  }

  static List<DateTime> paymentReminderDates(
    CreditCard card, {
    required DateTime now,
    int count = paymentScheduleSlots,
  }) {
    final dueDay = safePaymentDueDay(card.paymentDueDay);
    if (dueDay == null || count <= 0) return const [];

    final dates = <DateTime>[];
    var monthOffset = 0;
    while (dates.length < count && monthOffset < count * 2) {
      final dueDate = monthlyDate(now.year, now.month + monthOffset, dueDay);
      final reminderAt = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        safeHour(card.reminderHour),
      ).subtract(
          Duration(days: safeDaysBefore(card.paymentReminderDaysBefore)));

      if (reminderAt.isAfter(now)) {
        dates.add(reminderAt);
      }
      monthOffset++;
    }

    return dates;
  }

  static List<UpcomingCardDate> upcomingExpiries(
    List<CreditCard> cards, {
    required DateTime now,
    int lookaheadDays = expiryWidgetLookaheadDays,
  }) {
    final today = dateOnly(now);
    final notices = <UpcomingCardDate>[];

    for (final card in cards) {
      final expiryDate = parseExpiryDate(card.expirationDate);
      if (expiryDate == null) continue;

      final targetDate = dateOnly(expiryDate);
      final daysUntil = targetDate.difference(today).inDays;
      if (daysUntil < 0 || daysUntil > lookaheadDays) continue;
      notices.add(
        UpcomingCardDate(
          card: card,
          targetDate: targetDate,
          daysUntil: daysUntil,
        ),
      );
    }

    notices.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return notices;
  }

  static List<UpcomingCardDate> upcomingPayments(
    List<CreditCard> cards, {
    required DateTime now,
    int lookaheadDays = paymentWidgetLookaheadDays,
  }) {
    final today = dateOnly(now);
    final notices = <UpcomingCardDate>[];

    for (final card in cards) {
      final dueDay = safePaymentDueDay(card.paymentDueDay);
      if (dueDay == null) continue;

      final targetDate = nextPaymentDate(today, dueDay);
      final daysUntil = targetDate.difference(today).inDays;
      if (daysUntil < 0 || daysUntil > lookaheadDays) continue;
      notices.add(
        UpcomingCardDate(
          card: card,
          targetDate: targetDate,
          daysUntil: daysUntil,
        ),
      );
    }

    notices.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return notices;
  }

  static DateTime nextPaymentDate(DateTime now, int preferredDay) {
    final today = dateOnly(now);
    final thisMonth = monthlyDate(today.year, today.month, preferredDay);
    if (!thisMonth.isBefore(today)) return thisMonth;
    return monthlyDate(today.year, today.month + 1, preferredDay);
  }

  static DateTime monthlyDate(int year, int month, int preferredDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = preferredDay.clamp(1, lastDay).toInt();
    return DateTime(year, month, day);
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int? safePaymentDueDay(int? day) {
    if (day == null) return null;
    return day.clamp(1, 31).toInt();
  }

  static int safeDaysBefore(int days) {
    return days.clamp(0, 365).toInt();
  }

  static int safeHour(int hour) {
    return hour.clamp(0, 23).toInt();
  }
}

class UpcomingCardDate {
  final CreditCard card;
  final DateTime targetDate;
  final int daysUntil;

  const UpcomingCardDate({
    required this.card,
    required this.targetDate,
    required this.daysUntil,
  });
}
