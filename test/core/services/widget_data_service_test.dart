import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/services/widget_data_service.dart';

import '../../helpers/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = Harness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Map<String, Object?> saved() => {
        for (final c in h.channelCalls['home_widget'] ?? const [])
          if (c.method == 'saveWidgetData')
            (c.arguments as Map)['id'] as String: (c.arguments as Map)['data'],
      };

  // One test: the gate is a process-wide singleton that opens only once.
  test('publishes nothing until the first frame, then the full timeline',
      () async {
    final cards = [
      loyalty('a', 'Bakery', barcode: 'NOT-ENCODABLE-AS-EAN'),
      loyalty('b', 'Gym', format: 'QR_CODE', barcode: 'gym-42'),
    ];
    var done = false;
    final pending =
        WidgetDataService.instance.reconcile(cards).then((_) => done = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(done, isFalse);
    expect(h.channelCalls['home_widget'], isNull);

    WidgetDataService.instance.markUiReady();
    await pending.timeout(const Duration(seconds: 10));

    final data = saved();
    final timeline = jsonDecode(data['cw_timeline'] as String) as List;
    expect(timeline, hasLength(24));
    expect((timeline.first as Map)['ids'], containsAll(['a', 'b']));
    final payload = jsonDecode(data['cw_cards'] as String) as List;
    expect(
        payload.map((c) => (c as Map)['name']), containsAll(['Bakery', 'Gym']));
    for (final c in payload.cast<Map>()) {
      expect(c['bg'], matches(RegExp(r'^#[0-9A-F]{6}$')));
      expect(c['fg'], matches(RegExp(r'^#[0-9A-F]{6}$')));
    }
    // Labels follow the in-app language (raw keys here: no translations).
    expect(data.containsKey('cw_label_upnext'), isTrue);
    expect(data.containsKey('cw_label_add'), isTrue);
    // Legacy single-card keys for widgets placed by older versions.
    expect(data['last_loyalty_id'], isIn(['a', 'b']));
    expect(
        h.channelCalls['home_widget']!.any((c) => c.method == 'updateWidget'),
        isTrue);
    // No bank card or IBAN data ever reaches the widget store.
    expect(data.keys.where((k) => k.contains('iban') || k.contains('credit')),
        isEmpty);
  });
}
