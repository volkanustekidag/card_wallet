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

  IbanCard({
    required this.id,
    required this.bankName,
    required this.cardHolder,
    required this.iban,
    required this.swiftCode,
  });
}
