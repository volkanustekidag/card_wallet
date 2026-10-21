import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_share_flow.dart';
import 'package:wallet_app/feature/iban_card/widgets/shareable_iban_card.dart';

const _trIban = 'TR330006100519786457841326';
const _longName =
    'Ayşe Gülşen Çağlayan Öztürk-Karaağaçlıoğlu Uzunisimli Hesap Sahibi';

IbanCard _card({String holder = _longName, String swift = ''}) => IbanCard(
      id: 7,
      bankName: 'Türkiye İş Bankası Anonim Şirketi Çok Uzun Şube Adı',
      cardHolder: holder,
      iban: _trIban,
      swiftCode: swift,
    );

Future<void> _pump(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(
      color: const Color(0xFF808080),
      child: Center(
        child: RepaintBoundary(
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    ),
  ));
}

/// Real Poppins + Material Icons so the goldens show the actual image
/// instead of Ahem boxes.
Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    poppins.addFont(bytes('assets/fonts/poppins/Poppins-$w.ttf'));
  }
  await poppins.load();
  // flutter_tester lives in bin/cache/artifacts/engine/<platform>/.
  final icons = File('${File(Platform.resolvedExecutable).parent.parent.parent.path}'
      '/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(bytes(icons.path))).load();
  }
}

void main() {
  // Goldens are rasterized differently on Linux CI; they are a macOS-only
  // layout check. The widget tests below run everywhere.
  final skipGolden = !Platform.isMacOS;

  test('TR IBAN gets a payment QR from the existing generator', () {
    final qr = ShareableIbanCard.paymentQrData(_card());
    expect(qr, isNotNull);
    expect(qr, isNotEmpty);
  });

  testWidgets('free image: long name, no SWIFT, no QR, nothing overflows',
      (tester) async {
    final size = ShareableIbanCard.sizeFor(withQr: false);
    await _pump(tester, ShareableIbanCard(card: _card()), size);

    expect(tester.takeException(), isNull);
    expect(find.text('TR33 0006 1005 1978 6457 8413 26'), findsOneWidget);
    expect(find.textContaining('Ayşe Gülşen'), findsOneWidget);
    expect(find.text('SWIFT'), findsNothing);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Wallet'), findsNothing); // inside a Text.rich span
    expect(find.textContaining('CardWallet', findRichText: true),
        findsOneWidget);
  });

  testWidgets('premium image carries the QR and SWIFT', (tester) async {
    final card = _card(holder: 'Ali Veli', swift: 'isbktrisxxx');
    final size = ShareableIbanCard.sizeFor(withQr: true);
    await _pump(
      tester,
      ShareableIbanCard(
        card: card,
        qrData: ShareableIbanCard.paymentQrData(card),
      ),
      size,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('ISBKTRISXXX'), findsOneWidget);
  });

  testWidgets('golden: TR IBAN, long name, no SWIFT', (tester) async {
    await tester.runAsync(_loadFonts);
    final size = ShareableIbanCard.sizeFor(withQr: false);
    await _pump(tester, ShareableIbanCard(card: _card()), size);
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/shareable_iban_card_no_qr.png'),
    );
  }, skip: skipGolden);

  testWidgets('golden: with QR', (tester) async {
    await tester.runAsync(_loadFonts);
    final card = _card();
    final size = ShareableIbanCard.sizeFor(withQr: true);
    await _pump(
      tester,
      ShareableIbanCard(card: card, qrData: ShareableIbanCard.paymentQrData(card)),
      size,
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/shareable_iban_card_qr.png'),
    );
  }, skip: skipGolden);

  group('share sheet', () {
    Future<IbanShareChoice?> open(WidgetTester tester, bool isPremium,
        {required String tap}) async {
      IbanShareChoice? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showIbanShareSheet(context, isPremium: isPremium),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      if (tap.isNotEmpty) {
        await tester.tap(find.byKey(ValueKey(tap)));
        await tester.pumpAndSettle();
      }
      return result;
    }

    testWidgets('free user: text, image and "Add QR (Premium)"',
        (tester) async {
      await open(tester, false, tap: '');
      expect(find.byKey(const ValueKey('ibanShareText')), findsOneWidget);
      expect(find.byKey(const ValueKey('ibanShareImage')), findsOneWidget);
      expect(find.byKey(const ValueKey('ibanShareAddQr')), findsOneWidget);
    });

    testWidgets('free user can still pick the image', (tester) async {
      expect(await open(tester, false, tap: 'ibanShareImage'),
          IbanShareChoice.image);
    });

    testWidgets('free user "Add QR" routes to the paywall choice',
        (tester) async {
      expect(await open(tester, false, tap: 'ibanShareAddQr'),
          IbanShareChoice.addQrPremium);
    });

    testWidgets('premium user has no "Add QR" row', (tester) async {
      await open(tester, true, tap: '');
      expect(find.byKey(const ValueKey('ibanShareAddQr')), findsNothing);
      expect(find.byKey(const ValueKey('ibanShareImage')), findsOneWidget);
    });
  });

  test('text share body', () {
    expect(
      ibanShareText(_card(holder: 'Ali Veli')),
      'Türkiye İş Bankası Anonim Şirketi Çok Uzun Şube Adı\n'
      'IBAN: $_trIban\nAli Veli',
    );
  });
}
