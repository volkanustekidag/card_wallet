import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:pointycastle/export.dart' as pc;

/// PIN hashing helpers. PINs are hashed with PBKDF2-HMAC-SHA256 using a
/// per-user random salt. We never store the plaintext PIN.
///
/// 4-digit PINs have only 10,000 possible values, so PBKDF2's main
/// contribution here is *slowing each guess* rather than the keyspace
/// expansion it normally provides. 50k iterations is the sweet spot — it
/// adds meaningful per-guess cost for an offline attacker while staying
/// fast enough that the user perceives the create/verify as instant when
/// the work runs in a background isolate.
///
/// Both [hash] and [authenticateHash] dispatch through [compute] so the
/// PBKDF2 loop runs off the main isolate. Without the isolate hop the UI
/// freezes for ~3 s in debug builds (PointyCastle without the JIT-friendly
/// hot loop), the spinner stops animating, and snackbars only appear after
/// the work finishes — which is the "şifre kaldırırken/eklerken bekliyor"
/// regression the user hit.
class PinHasher {
  static const int _iterations = 50000;
  static const int _saltLengthBytes = 16;
  static const int _keyLengthBytes = 32;

  /// Generates a fresh random salt suitable for [hash]. Synchronous —
  /// reading 16 random bytes from `Random.secure` is a microsecond op.
  static String generateSalt() {
    final rand = Random.secure();
    final bytes = Uint8List(_saltLengthBytes);
    for (var i = 0; i < _saltLengthBytes; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Returns the base64-encoded PBKDF2-HMAC-SHA256 hash of [pin] with
  /// [salt]. Runs in a background isolate via [compute] so the UI thread
  /// stays responsive (loader animation, snackbar, page pop all work
  /// during the hash).
  static Future<String> hash(String pin, String salt) {
    return compute(_pbkdf2, _Pbkdf2Input(pin: pin, salt: salt));
  }

  /// Constant-time equality check to mitigate timing attacks against the
  /// PIN. Both inputs are short (32-byte digests as base64) so this is
  /// cheap; keeping it synchronous lets the auth service inline it after
  /// awaiting [hash].
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

/// Top-level isolate entry point. Must be a top-level or static function
/// for [compute] to dispatch it across isolates.
String _pbkdf2(_Pbkdf2Input input) {
  final saltBytes = base64Decode(input.salt);
  final params = pc.Pbkdf2Parameters(
    Uint8List.fromList(saltBytes),
    PinHasher._iterations,
    PinHasher._keyLengthBytes,
  );
  final derivator = pc.PBKDF2KeyDerivator(
    pc.HMac(pc.SHA256Digest(), 64),
  )..init(params);
  final derived = derivator.process(Uint8List.fromList(utf8.encode(input.pin)));
  return base64Encode(derived);
}

class _Pbkdf2Input {
  final String pin;
  final String salt;
  const _Pbkdf2Input({required this.pin, required this.salt});
}
