import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';

class _RecordingPlatform implements SharePlatform {
  final List<ShareParams> calls = [];

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    return const ShareResult('', ShareResultStatus.success);
  }
}

void main() {
  late _RecordingPlatform platform;
  late SharePlus plugin;

  setUp(() {
    platform = _RecordingPlatform();
    plugin = SharePlus.custom(platform);
  });

  test('empty or blank text never reaches share_plus', () async {
    expect(await shareText('', sharePlus: plugin), isFalse);
    expect(await shareText('  \n ', sharePlus: plugin), isFalse);
    expect(platform.calls, isEmpty);
  });

  test('non-empty text is shared as is', () async {
    expect(
      await shareText('Bank\nIBAN: TR00', subject: 's', sharePlus: plugin),
      isTrue,
    );
    expect(platform.calls.single.text, 'Bank\nIBAN: TR00');
    expect(platform.calls.single.subject, 's');
  });
}
