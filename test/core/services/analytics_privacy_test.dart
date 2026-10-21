import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';

const _allowedParams = {
  'source', 'type', 'method', 'provider', 'error_key', 'card_type', 'masked',
  'kind', 'trigger', 'feature', 'value',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final events = <String, Map<String, Object>?>{};

  setUp(() {
    events.clear();
    AnalyticsService.debugSink = (name, params) => events[name] = params;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() => AnalyticsService.debugSink = null);

  test('new events only carry whitelisted, non-sensitive params', () async {
    final a = AnalyticsService.instance;
    await a.logBarcodeShown('detail_page');
    await a.logScanStarted(type: 'credit', method: AnalyticsScanMethod.camera);
    await a.logScanSucceeded(type: 'iban', method: AnalyticsScanMethod.qrGallery);
    await a.logScanFailed(type: 'loyalty', method: AnalyticsScanMethod.gallery);
    await a.logWalletExportAttempt('apple');
    await a.logWalletExportSuccess('google');
    await a.logWalletExportFailed(provider: 'apple', errorKey: 'walletExportFailed');
    await a.logBackupCreated();
    await a.logBackupRestored();
    await a.logCardCopied('credit');
    await a.logCardShared(cardType: 'credit', masked: true);
    await a.logReminderEnabled('payment');
    await a.logPaywallDismissed(trigger: 'feature_gate', feature: 'walletExport');
    await a.logPremiumGateTapped('qrCreate');
    await a.setCardCounts(credit: 2, iban: 1, loyalty: 5);
    await a.setHasPin(true);

    expect(events.keys, containsAll(<String>[
      'barcode_shown', 'scan_started', 'scan_succeeded', 'scan_failed',
      'wallet_export_attempt', 'wallet_export_success', 'wallet_export_failed',
      'backup_created', 'backup_restored', 'card_copied', 'card_shared',
      'reminder_enabled', 'paywall_dismissed', 'premium_gate_tapped',
      'user_property:credit_card_count', 'user_property:iban_card_count',
      'user_property:loyalty_card_count', 'user_property:has_pin',
    ]));
    for (final entry in events.entries) {
      for (final param in (entry.value ?? const {}).entries) {
        expect(_allowedParams, contains(param.key), reason: entry.key);
        // No card numbers, IBANs or barcodes: no long digit runs.
        expect('${param.value}', isNot(matches(RegExp(r'\d{6,}'))),
            reason: '${entry.key}.${param.key}');
      }
    }
    expect(events['card_shared'], {'card_type': 'credit', 'masked': 'true'});
  });

  test('copying a card logs the type, never the value', () async {
    await SensitiveClipboard.copy('4111111111111111', cardType: 'credit');
    expect(events['card_copied'], {'card_type': 'credit'});
    expect(events.toString(), isNot(contains('4111111111111111')));
  });
}
