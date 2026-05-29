import 'package:hive/hive.dart';

part 'iban_card.g.dart';

@HiveType(typeId: 2)
class IbanCard extends HiveObject {
  @HiveField(0)
  late dynamic id;

  @HiveField(1)
  late String bankName;

  @HiveField(2)
  late String cardHolder;

  @HiveField(3)
  late String iban;

  @HiveField(4)
  late String swiftCode;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  List<String>? tags;

  IbanCard({
    required this.id,
    required this.bankName,
    required this.cardHolder,
    required this.iban,
    required this.swiftCode,
    this.createdAt,
    this.notes,
    this.tags,
  });
}
