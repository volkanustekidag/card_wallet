import 'package:hive/hive.dart';

part 'credit_card.g.dart';

@HiveType(typeId: 3)
class CreditCard extends HiveObject {
  @HiveField(0)
  late int id;
  @HiveField(1)
  late String bankName;
  @HiveField(2)
  late String creditCardNumber;
  @HiveField(3)
  late String cardHolder;
  @HiveField(4)
  late String expirationDate;
  @HiveField(5)
  late String cvc2;
  @HiveField(6)
  late int cardColorId;

  CreditCard(this.id, this.bankName, this.creditCardNumber, this.cardHolder,
      this.expirationDate, this.cvc2, this.cardColorId);
}
