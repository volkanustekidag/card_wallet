import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';

IbanCard _card({String holder = 'Ada Lovelace', String iban = ''}) => IbanCard(
      id: '1',
      bankName: '',
      cardHolder: holder,
      iban: iban,
      swiftCode: '',
    );

void main() {
  test('an empty IBAN cannot be saved', () {
    expect(AddIbanCardController.hasRequiredFields(_card()), isFalse);
    expect(AddIbanCardController.hasRequiredFields(_card(iban: 'TR33 0006')),
        isFalse);
  });

  test('a holder name is required', () {
    expect(
      AddIbanCardController.hasRequiredFields(
        _card(holder: '  ', iban: 'TR33 0006 1005 1978 6457 8413 26'),
      ),
      isFalse,
    );
  });

  test('holder + IBAN is enough (bank and SWIFT optional)', () {
    expect(
      AddIbanCardController.hasRequiredFields(
        _card(iban: 'TR33 0006 1005 1978 6457 8413 26'),
      ),
      isTrue,
    );
    expect(
      AddIbanCardController.hasRequiredFields(_card(iban: 'NO9386011117947')),
      isTrue,
    );
  });
}
