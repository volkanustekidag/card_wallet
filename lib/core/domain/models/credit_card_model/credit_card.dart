import 'package:hive/hive.dart';

part 'credit_card.g.dart';

@HiveType(typeId: 3)
class CreditCard extends HiveObject {
  @HiveField(0)
  late dynamic id;
  @HiveField(1)
  late String bankName;
  @HiveField(2)
  late String creditCardNumber;
  @HiveField(3)
  late String cardHolder;
  @HiveField(4)
  late String expirationDate;
  @HiveField(6)
  late int cardColorId;
  @HiveField(7)
  DateTime? createdAt;
  @HiveField(8)
  String? notes;
  @HiveField(9)
  List<String>? tags;
  @HiveField(10, defaultValue: false)
  bool expiryReminderEnabled;
  @HiveField(11, defaultValue: 30)
  int expiryReminderDaysBefore;
  @HiveField(12, defaultValue: false)
  bool paymentReminderEnabled;
  @HiveField(13)
  int? paymentDueDay;
  @HiveField(14, defaultValue: 3)
  int paymentReminderDaysBefore;
  @HiveField(15, defaultValue: 9)
  int reminderHour;

  CreditCard({
    required this.id,
    required this.bankName,
    required this.creditCardNumber,
    required this.cardHolder,
    required this.expirationDate,
    required this.cardColorId,
    this.createdAt,
    this.notes,
    this.tags,
    this.expiryReminderEnabled = false,
    this.expiryReminderDaysBefore = 30,
    this.paymentReminderEnabled = false,
    this.paymentDueDay,
    this.paymentReminderDaysBefore = 3,
    this.reminderHour = 9,
  });
}
