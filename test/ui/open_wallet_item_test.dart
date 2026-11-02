import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/feature/card_detail/bank_card_page.dart';
import 'package:wallet_app/feature/card_detail/iban_page.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart';
import 'package:wallet_app/ui/navigation/open_wallet_item.dart';

import '../helpers/harness.dart';

void main() {
  final h = Harness();
  setUp(() async {
    await h.setUp();
    await LoyaltyCardService().openBox();
  });
  tearDown(h.tearDown);

  Future<void> openItem(WidgetTester tester, WalletItem item) async {
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openWalletItem(context, item),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tapIo(tester, find.text('open'));
  }

  testWidgets('loyalty opens Checkout', (tester) async {
    await openItem(tester, WalletItem.loyalty(loyalty('l', 'Gym')));
    expect(find.byType(LoyaltyCardDetailPage), findsOneWidget);
  });

  testWidgets('bank card opens its detail', (tester) async {
    await openItem(tester, WalletItem.credit(credit('c')));
    expect(find.byType(BankCardPage), findsOneWidget);
  });

  testWidgets('IBAN opens its detail', (tester) async {
    await openItem(tester, WalletItem.iban(iban(1)));
    expect(find.byType(IbanPage), findsOneWidget);
  });
}
