import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.cardwallet/sensitive_clipboard');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> nativeCalls;
  late List<MethodCall> platformCalls;

  setUp(() {
    nativeCalls = [];
    platformCalls = [];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('copies through the native channel with a 60 s expiry', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      return true;
    });

    await SensitiveClipboard.copy('TR330006100519786457841326');

    expect(nativeCalls, hasLength(1));
    expect(nativeCalls.single.method, 'copy');
    expect(nativeCalls.single.arguments, {
      'text': 'TR330006100519786457841326',
      'expiresInSeconds': 60,
    });
    expect(
      platformCalls.where((c) => c.method == 'Clipboard.setData'),
      isEmpty,
    );
  });

  test('falls back to Clipboard.setData without the native channel',
      () async {
    await SensitiveClipboard.copy('4111111111111111');

    final setData =
        platformCalls.where((c) => c.method == 'Clipboard.setData').toList();
    expect(setData, hasLength(1));
    expect((setData.single.arguments as Map)['text'], '4111111111111111');
  });
}
