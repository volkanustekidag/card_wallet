import 'package:hive/hive.dart';

part 'iban_card.g.dart';

@HiveType(typeId: 2)
class IbanCard extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String bankName;

  @HiveField(2)
  late String cardHolder;

  @HiveField(3)
  late String iban;

  @HiveField(4)
  late String swiftCode;

  IbanCard(this.bankName, this.cardHolder, this.iban, this.swiftCode, this.id);
}
