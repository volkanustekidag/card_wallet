import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:wallet_app/core/utils/pin_hasher.dart';

/// The PointyCastle derivation PINs were stored with before.
String _reference(String pin, String salt) {
  final d = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
    ..init(
        pc.Pbkdf2Parameters(Uint8List.fromList(base64Decode(salt)), 50000, 32));
  return base64Encode(d.process(Uint8List.fromList(utf8.encode(pin))));
}

void main() {
  test('same hash as the stored PointyCastle one: existing PINs still open',
      () async {
    for (final pin in ['0000', '1234', '9876']) {
      final salt = PinHasher.generateSalt();
      expect(await PinHasher.hash(pin, salt), _reference(pin, salt));
    }
  });

  test('deterministic per salt, 32-byte key', () async {
    final a = await PinHasher.hash('1234', base64Encode(utf8.encode('salt')));
    final b = await PinHasher.hash('1234', base64Encode(utf8.encode('salt')));
    final c = await PinHasher.hash('1234', base64Encode(utf8.encode('salT')));
    expect(a, b);
    expect(a, isNot(c));
    expect(base64Decode(a), hasLength(32));
  });

  test('constant-time compare', () {
    expect(PinHasher.constantTimeEquals('abc', 'abc'), isTrue);
    expect(PinHasher.constantTimeEquals('abc', 'abd'), isFalse);
    expect(PinHasher.constantTimeEquals('abc', 'ab'), isFalse);
  });
}
