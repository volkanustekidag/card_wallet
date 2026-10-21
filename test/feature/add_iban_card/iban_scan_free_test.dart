import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// IBAN scanning (camera OCR, QR camera, QR from gallery) is free. Source
/// guard so a future premium check on a scan path fails CI instead of
/// quietly reappearing on the paywall.
const _scanPaths = [
  'lib/feature/add_iban_card/widgets/iban_text_field.dart',
  'lib/feature/add_iban_card/widgets/iban_text_forms.dart',
  'lib/core/data/local_services/card_services/iban_card/qr_iban_scanner_service.dart',
];

final _premiumCheck =
    RegExp(r'isPremium|openPremiumGate|PremiumController|premiumLocked');

void main() {
  test('IBAN scan paths have no premium check', () {
    for (final path in _scanPaths) {
      final source = File(path).readAsStringSync();
      expect(_premiumCheck.hasMatch(source), isFalse, reason: path);
    }
  });

  test('nothing opens the paywall for ibanScan', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains("'ibanScan'"))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
