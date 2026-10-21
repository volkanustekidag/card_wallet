import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/services/barcode_display_boost.dart';

void main() {
  late List<String> calls;
  late String? stored;

  BarcodeDisplayBoost build() => BarcodeDisplayBoost(
        boost: () async => calls.add('boost'),
        restore: () async => calls.add('restore'),
        readSetting: () async => stored,
        writeSetting: (v) async => stored = v,
      );

  setUp(() {
    calls = [];
    stored = null;
  });

  test('boosts on open and restores on close (default on)', () async {
    final b = build();
    await b.acquire();
    expect(calls, ['boost']);
    await b.release();
    expect(calls, ['boost', 'restore']);
  });

  test('overlapping views keep the boost until the last one closes',
      () async {
    final b = build();
    await b.acquire();
    await b.acquire();
    await b.release();
    expect(calls, ['boost']);
    await b.release();
    expect(calls, ['boost', 'restore']);
  });

  test('does nothing when turned off in settings', () async {
    stored = 'false';
    final b = build();
    await b.acquire();
    await b.release();
    expect(calls, isEmpty);
  });

  test('turning it off while a barcode is open restores immediately',
      () async {
    final b = build();
    await b.acquire();
    await b.setEnabled(false);
    expect(calls, ['boost', 'restore']);
    expect(stored, 'false');
    await b.release();
    expect(calls, ['boost', 'restore']);
  });

  test('extra releases are ignored', () async {
    final b = build();
    await b.release();
    expect(calls, isEmpty);
  });
}
