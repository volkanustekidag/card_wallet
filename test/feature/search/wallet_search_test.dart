import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/search/wallet_search.dart';

final _credit = WalletItem.credit(CreditCard(
  id: 1,
  bankName: 'Türkiye İş Bankası',
  creditCardNumber: '4111 1111 1111 4242',
  cardHolder: 'Ayşe Yılmaz',
  expirationDate: '12/30',
  cardColorId: 0,
  notes: 'secret note',
  tags: ['iş', kFavoriteTag],
));

final _iban = WalletItem.iban(IbanCard(
  id: 2,
  bankName: 'Garanti BBVA',
  cardHolder: 'Çağrı Öztürk',
  iban: 'TR33 0006 1005 1978 6457 8413 26',
  swiftCode: '',
));

final _loyalty = WalletItem.loyalty(LoyaltyCard(
  id: 'l1',
  name: 'Migros Money',
  brand: 'Migros',
  barcode: '9876543210',
  barcodeFormat: 'EAN_13',
  colorId: 0,
  notes: 'Kasada telefon numarası',
  tags: ['market'],
));

final _all = [_credit, _iban, _loyalty];

List<WalletItemKind> _kinds(String q) =>
    searchWallet(_all, q).map((i) => i.kind).toList();

void main() {
  test('empty query returns nothing', () {
    expect(searchWallet(_all, '   '), isEmpty);
  });

  test('credit: holder, bank, tag and last 4, Turkish-insensitive', () {
    expect(_kinds('is bankasi'), [WalletItemKind.credit]);
    expect(_kinds('AYSE'), [WalletItemKind.credit]);
    expect(_kinds('İŞ'), [WalletItemKind.credit]); // tag + bank
    expect(_kinds('4242'), [WalletItemKind.credit]);
  });

  test('credit: full number, notes and the favourite flag are not searched',
      () {
    expect(searchWallet(_all, '4111111111114242'), isEmpty);
    expect(searchWallet(_all, '4111'), isEmpty);
    expect(searchWallet(_all, 'secret'), isEmpty);
    expect(searchWallet(_all, 'favorite'), isEmpty);
  });

  test('IBAN: holder, bank and last 4 only', () {
    expect(_kinds('cagri ozturk'), [WalletItemKind.iban]);
    expect(_kinds('garanti'), [WalletItemKind.iban]);
    expect(_kinds('1326'), [WalletItemKind.iban]);
    expect(searchWallet(_all, 'TR33'), isEmpty);
  });

  test('loyalty: name, brand, tag and note', () {
    expect(_kinds('mıgros'), [WalletItemKind.loyalty]);
    expect(_kinds('MARKET'), [WalletItemKind.loyalty]);
    expect(_kinds('telefon numarasi'), [WalletItemKind.loyalty]);
    expect(searchWallet(_all, '98765'), isEmpty); // barcode not searched
  });

  test('every word must match, in any field', () {
    expect(_kinds('migros market'), [WalletItemKind.loyalty]);
    expect(searchWallet(_all, 'migros garanti'), isEmpty);
  });

  test('results keep the input order', () {
    final mixed = [_loyalty, _iban, _credit];
    final both = WalletItem.loyalty(LoyaltyCard(
      id: 'l2',
      name: 'Garanti Bonus Market',
      barcode: '1',
      barcodeFormat: 'EAN_13',
      colorId: 0,
    ));
    expect(
      searchWallet([...mixed, both], 'garanti').map((i) => i.id),
      ['2', 'l2'],
    );
  });

  test('last4 strips spaces', () {
    expect(last4('4111 1111 1111 4242'), '4242');
    expect(last4('TR33 0006 1005 1978 6457 8413 26'), '1326');
    expect(last4('12'), '12');
  });
}
