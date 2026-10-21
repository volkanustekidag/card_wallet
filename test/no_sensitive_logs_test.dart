import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Card numbers, IBANs, barcodes and holder names must never reach logs:
/// `debugPrint` output ends up in release device logs and bug reports.
///
/// Stricter than `grep -rnE "debugPrint\(.*(creditCardNumber|\.iban|barcode|cardHolder)" lib`:
/// it also sees calls whose arguments span several lines.
final _sensitive = RegExp(
  r'creditCardNumber|\.iban\b|\$iban|barcode|cardHolder|holderName|cvc',
  caseSensitive: false,
);

void main() {
  test('no debugPrint/print call logs card data', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final call in RegExp(r'\b(?:debugPrint|print)\(').allMatches(source)) {
        var depth = 1;
        var i = call.end;
        while (depth > 0 && i < source.length) {
          final c = source[i];
          if (c == '(') depth++;
          if (c == ')') depth--;
          i++;
        }
        final args = source.substring(call.end, i - 1);
        if (_sensitive.hasMatch(args)) {
          final line = '\n'.allMatches(source.substring(0, call.start)).length + 1;
          offenders.add('${file.path}:$line  ${args.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
