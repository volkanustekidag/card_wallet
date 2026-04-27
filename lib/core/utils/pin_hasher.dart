import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

/// PIN hashing helpers. PINs are hashed with PBKDF2-HMAC-SHA256 using
/// a per-user random salt. We never store the plaintext PIN.
class PinHasher {
  static const int _iterations = 100000;
  static const int _saltLengthBytes = 16;
  static const int _keyLengthBytes = 32;

  /// Generates a fresh random salt suitable for [hash].
  static String generateSalt() {
    final rand = Random.secure();
    final bytes = Uint8List(_saltLengthBytes);
    for (var i = 0; i < _saltLengthBytes; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Returns the base64 encoded PBKDF2-HMAC-SHA256 hash of [pin] with [salt].
  /// Both inputs are required; they are decoded/encoded as utf-8/base64.
  static String hash(String pin, String salt) {
    final saltBytes = base64Decode(salt);
    final params = pc.Pbkdf2Parameters(
      Uint8List.fromList(saltBytes),
      _iterations,
      _keyLengthBytes,
    );
    final derivator = pc.PBKDF2KeyDerivator(
      pc.HMac(pc.SHA256Digest(), 64),
    )..init(params);
    final derived = derivator.process(Uint8List.fromList(utf8.encode(pin)));
    return base64Encode(derived);
  }

  /// Constant-time equality check to mitigate timing attacks against the PIN.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
