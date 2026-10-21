import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/data/services/backup_crypto.dart';
import 'package:wallet_app/core/data/services/backup_service.dart';

final _payload = <String, dynamic>{
  'creditCards': [
    {
      'id': 1,
      'bankName': 'Test Bank',
      'creditCardNumber': '4111111111111111',
      'cardHolder': 'A B',
      'expirationDate': '12/30',
      'cardColorId': 2,
      'tags': ['favorite'],
    },
  ],
  'ibanCards': [
    {'id': 2, 'iban': 'TR330006100519786457841326', 'cardHolder': 'A B'},
  ],
  'loyaltyCards': [
    {'id': 'l1', 'name': 'Shop', 'barcode': '123', 'barcodeFormat': 'EAN_13'},
  ],
};

String _encryptedFile(String password, {int iterations = 1000}) {
  final envelope = encryptBackupPayload(BackupEncryptRequest(
    plaintext: jsonEncode(_payload),
    password: password,
    timestamp: DateTime(2026, 10, 21),
    iterations: iterations,
  ));
  return jsonEncode(envelope);
}

Future<Map<String, dynamic>?> _decode(
  String raw, {
  String? password = 'secret123',
  bool acceptPlaintext = true,
}) =>
    BackupService.decodeBackup(
      raw,
      passwordProvider: () async => password,
      confirmLegacyPlaintext: () async => acceptPlaintext,
    );

Matcher _backupError(BackupErrorKind kind) =>
    isA<BackupError>().having((e) => e.kind, 'kind', kind);

void main() {
  group('encrypted v2.1', () {
    test('round-trips the full payload', () async {
      final data = await _decode(_encryptedFile('secret123'));
      expect(data, _payload);
    });

    test('envelope never contains the plaintext', () {
      final raw = _encryptedFile('secret123');
      expect(raw, isNot(contains('4111111111111111')));
      expect(raw, isNot(contains('TR330006100519786457841326')));
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      expect(envelope['version'], kBackupVersion);
      expect(envelope['algorithm'], 'AES-256-GCM');
    });

    test('round-trips with the production iteration count', () async {
      final raw = _encryptedFile('secret123', iterations: kBackupPbkdf2Iterations);
      expect(await _decode(raw), _payload);
    });

    test('wrong password is reported as wrongPassword', () async {
      await expectLater(
        _decode(_encryptedFile('secret123'), password: 'nope-nope'),
        throwsA(_backupError(BackupErrorKind.wrongPassword)),
      );
    });

    test('tampered ciphertext fails authentication', () async {
      final envelope =
          jsonDecode(_encryptedFile('secret123')) as Map<String, dynamic>;
      final bytes = base64Decode(envelope['data'] as String);
      bytes[0] ^= 0xFF;
      envelope['data'] = base64Encode(bytes);
      await expectLater(
        _decode(jsonEncode(envelope)),
        throwsA(_backupError(BackupErrorKind.wrongPassword)),
      );
    });

    test('missing password is passwordRequired', () async {
      await expectLater(
        _decode(_encryptedFile('secret123'), password: null),
        throwsA(_backupError(BackupErrorKind.passwordRequired)),
      );
    });

    test('iterations encoded as a double are accepted', () async {
      final envelope =
          jsonDecode(_encryptedFile('secret123')) as Map<String, dynamic>;
      envelope['iterations'] = 1000.0;
      expect(await _decode(jsonEncode(envelope)), _payload);
    });
  });

  group('legacy v1.0 (plaintext)', () {
    final legacy = jsonEncode({'version': '1.0', 'data': _payload});

    test('restores after the user accepts the warning', () async {
      expect(await _decode(legacy), _payload);
    });

    test('returns null when the user declines the warning', () async {
      expect(await _decode(legacy, acceptPlaintext: false), isNull);
    });
  });

  group('content validation', () {
    test('non-JSON files are rejected', () async {
      await expectLater(
        _decode('PK\u0003\u0004 not json'),
        throwsA(_backupError(BackupErrorKind.invalidFormat)),
      );
    });

    test('JSON without version is rejected', () async {
      await expectLater(
        _decode(jsonEncode({'hello': 'world'})),
        throwsA(_backupError(BackupErrorKind.invalidFormat)),
      );
    });

    test('unknown versions are rejected', () async {
      await expectLater(
        _decode(jsonEncode({'version': '9.0', 'data': {}})),
        throwsA(_backupError(BackupErrorKind.invalidFormat)),
      );
    });

    test('payload without card lists is rejected', () async {
      await expectLater(
        _decode(jsonEncode({'version': '1.0', 'data': {'creditCards': 1}})),
        throwsA(_backupError(BackupErrorKind.invalidFormat)),
      );
    });
  });
}
