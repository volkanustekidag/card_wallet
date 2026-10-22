import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Scanning (live camera, photos: cards, barcodes, IBANs incl. SEPA QR)
/// is free. Source guard so a future premium check on a scan path fails CI
/// instead of quietly reappearing on the paywall.
const _scanPaths = [
  'lib/feature/scanner/live_scanner_page.dart',
  'lib/feature/scanner/scan_analyzer.dart',
  'lib/feature/add_iban_card/add_iban_card_page.dart',
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
