import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';

/// What to call a bank card: its bank, else its network ("Visa"), else
/// the generic "Card". The bank stays optional and is never filled in with
/// the network, so editing the card shows an empty bank field.
String creditCardLabel(CreditCard card) {
  final bank = card.bankName.trim();
  if (bank.isNotEmpty) return bank;
  final network = CardBankDetector.networkFor(card.creditCardNumber);
  return network == CardNetwork.unknown ? 'cwTypeCard'.tr() : network.label;
}
