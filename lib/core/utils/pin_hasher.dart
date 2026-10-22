import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show compute;

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
///
/// PBKDF2-HMAC-SHA256 with one output block (the key is 32 bytes, the
/// digest size). Byte-for-byte the same result as PointyCastle's
/// PBKDF2KeyDerivator, which it replaced: that one took ~2-8 s per unlock
/// on phones. Here the HMAC key pads are hashed once, so each of the 50k
/// iterations is two SHA-256 compressions on preallocated buffers.
String _pbkdf2(_Pbkdf2Input input) {
  List<int> key = utf8.encode(input.pin);
  if (key.length > 64) key = crypto.sha256.convert(key).bytes;
  final ipad = Uint8List(64), opad = Uint8List(64);
  for (var i = 0; i < 64; i++) {
    final k = i < key.length ? key[i] : 0;
    ipad[i] = k ^ 0x36;
    opad[i] = k ^ 0x5c;
  }
  final inner = _Sha256.of(ipad), outer = _Sha256.of(opad);

  // U1 = HMAC(salt || INT(1)), via package:crypto (salt has any length).
  final hmac = crypto.Hmac(crypto.sha256, utf8.encode(input.pin));
  final u = Uint32List(8);
  final first = hmac.convert([...base64Decode(input.salt), 0, 0, 0, 1]).bytes;
  for (var i = 0; i < 8; i++) {
    u[i] = first[i * 4] << 24 |
        first[i * 4 + 1] << 16 |
        first[i * 4 + 2] << 8 |
        first[i * 4 + 3];
  }
  final out = Uint32List.fromList(u);
  final w = Uint32List(64), state = Uint32List(8);
  for (var n = 1; n < PinHasher._iterations; n++) {
    // U(n) = H(opad || H(ipad || U(n-1))), each a single padded block.
    _Sha256.digestBlock(inner, u, state, w);
    _Sha256.digestBlock(outer, state, u, w);
    for (var i = 0; i < 8; i++) {
      out[i] ^= u[i];
    }
  }
  final bytes = Uint8List(32);
  for (var i = 0; i < 8; i++) {
    bytes[i * 4] = out[i] >> 24;
    bytes[i * 4 + 1] = out[i] >> 16;
    bytes[i * 4 + 2] = out[i] >> 8;
    bytes[i * 4 + 3] = out[i];
  }
  return base64Encode(bytes);
}

/// Just enough SHA-256 for HMAC over 32-byte messages.
abstract final class _Sha256 {
  static final Uint32List _k = Uint32List.fromList(const [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ]);

  /// State after compressing one 64-byte [block] from the initial hash.
  static Uint32List of(Uint8List block) {
    final h = Uint32List.fromList(const [
      0x6a09e667,
      0xbb67ae85,
      0x3c6ef372,
      0xa54ff53a,
      0x510e527f,
      0x9b05688c,
      0x1f83d9ab,
      0x5be0cd19,
    ]);
    final w = Uint32List(64);
    for (var i = 0; i < 16; i++) {
      w[i] = block[i * 4] << 24 |
          block[i * 4 + 1] << 16 |
          block[i * 4 + 2] << 8 |
          block[i * 4 + 3];
    }
    _compress(h, w);
    return h;
  }

  /// [out] = SHA-256 of (the 64 bytes behind [from]) || [msg], where [msg]
  /// is 32 bytes: one more block holding msg + padding (total 96 bytes).
  static void digestBlock(
      Uint32List from, Uint32List msg, Uint32List out, Uint32List w) {
    for (var i = 0; i < 8; i++) {
      w[i] = msg[i];
      out[i] = from[i];
    }
    w[8] = 0x80000000;
    for (var i = 9; i < 15; i++) {
      w[i] = 0;
    }
    w[15] = 96 * 8;
    _compress(out, w);
  }

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

  static void _compress(Uint32List h, Uint32List w) {
    for (var i = 16; i < 64; i++) {
      final a = w[i - 15], b = w[i - 2];
      final s0 = _rotr(a, 7) ^ _rotr(a, 18) ^ (a >> 3);
      final s1 = _rotr(b, 17) ^ _rotr(b, 19) ^ (b >> 10);
      w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ (~e & g);
      final t1 = (hh + s1 + ch + _k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & 0xffffffff;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xffffffff;
    }
    h[0] += a;
    h[1] += b;
    h[2] += c;
    h[3] += d;
    h[4] += e;
    h[5] += f;
    h[6] += g;
    h[7] += hh;
  }
}

class _Pbkdf2Input {
  final String pin;
  final String salt;
  const _Pbkdf2Input({required this.pin, required this.salt});
}
