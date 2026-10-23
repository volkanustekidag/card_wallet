import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

/// Pure crypto for backup files. Everything here is synchronous, CPU-bound
/// (PBKDF2 with 100k iterations takes hundreds of ms on mid-range phones) and
/// free of plugins, so [BackupService] runs it through `compute()` to keep
/// the UI thread responsive.

/// 2.2: GCM with its 128-bit authentication tag (PointyCastle). Backups up
/// to 2.1 were written by the `encrypt` package, whose GCM output carries
/// no tag; they still open, unauthenticated.
const String kBackupVersion = '2.2';
const int kBackupPbkdf2Iterations = 100000;
const int _keyLengthBytes = 32;
const int _saltLengthBytes = 16;
const int _gcmNonceLengthBytes = 12;

/// Arguments for [encryptBackupPayload]. Plain record of sendable values.
class BackupEncryptRequest {
  final String plaintext;
  final String password;
  final int iterations;
  final DateTime timestamp;

  const BackupEncryptRequest({
    required this.plaintext,
    required this.password,
    required this.timestamp,
    this.iterations = kBackupPbkdf2Iterations,
  });
}

/// Arguments for [decryptBackupPayload].
class BackupDecryptRequest {
  final Map<String, dynamic> envelope;
  final String password;

  const BackupDecryptRequest({required this.envelope, required this.password});
}

/// Thrown by [decryptBackupPayload]; [wrongPassword] covers both a bad
/// password and a tampered/corrupted file (GCM can't tell them apart).
class BackupCryptoException implements Exception {
  final bool wrongPassword;
  final String message;
  const BackupCryptoException(this.message, {this.wrongPassword = false});

  @override
  String toString() => 'BackupCryptoException: $message';
}

/// AES-256-GCM with a PBKDF2-HMAC-SHA256 key. Returns the JSON envelope.
Map<String, dynamic> encryptBackupPayload(BackupEncryptRequest request) {
  final salt = _randomBytes(_saltLengthBytes);
  final nonce = _randomBytes(_gcmNonceLengthBytes);
  final key = deriveBackupKey(request.password, salt, request.iterations);

  final sealed = _gcm(
      true, key, nonce, Uint8List.fromList(utf8.encode(request.plaintext)));

  return <String, dynamic>{
    'version': kBackupVersion,
    'encrypted': true,
    'algorithm': 'AES-256-GCM',
    // Ciphertext followed by the tag; decryption checks it.
    'tag': 128,
    'kdf': 'PBKDF2-HMAC-SHA256',
    'iterations': request.iterations,
    'salt': base64Encode(salt),
    'nonce': base64Encode(nonce),
    'data': base64Encode(sealed),
    'timestamp': request.timestamp.toIso8601String(),
  };
}

/// Decrypts a v2.x envelope (AES-256-GCM, or legacy v2.0 AES-256-CBC) and
/// returns the decoded card payload.
Map<String, dynamic> decryptBackupPayload(BackupDecryptRequest request) {
  final envelope = request.envelope;
  final saltStr = envelope['salt'];
  final algorithm = (envelope['algorithm'] as String?) ?? 'AES-256-CBC';
  final nonceStr = envelope['nonce'];
  final ivStr = envelope['iv'];
  final dataStr = envelope['data'];
  // Tolerate hand-edited backups where iterations is encoded as a double.
  final iterations =
      (envelope['iterations'] as num?)?.toInt() ?? kBackupPbkdf2Iterations;
  if (saltStr is! String || dataStr is! String) {
    throw const BackupCryptoException('Encrypted backup missing salt/data');
  }

  final Uint8List key;
  try {
    key = deriveBackupKey(request.password, base64Decode(saltStr), iterations);
  } on FormatException {
    throw const BackupCryptoException('Encrypted backup has a bad salt');
  }

  try {
    if (algorithm == 'AES-256-GCM' && envelope['tag'] == 128) {
      if (nonceStr is! String) {
        throw const FormatException('Encrypted backup missing nonce');
      }
      // Throws on a wrong password or any modified byte.
      final plain =
          _gcm(false, key, base64Decode(nonceStr), base64Decode(dataStr));
      return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    }
    late final enc.Encrypter encrypter;
    late final enc.IV iv;
    if (algorithm == 'AES-256-GCM') {
      // Up to 2.1: untagged GCM from the `encrypt` package.
      if (nonceStr is! String) {
        throw const FormatException('Encrypted backup missing nonce');
      }
      encrypter = enc.Encrypter(
        enc.AES(enc.Key(key), mode: enc.AESMode.gcm, padding: null),
      );
      iv = enc.IV(base64Decode(nonceStr));
    } else if (algorithm == 'AES-256-CBC') {
      if (ivStr is! String) {
        throw const FormatException('Encrypted backup missing iv');
      }
      // Legacy v2.0 backup format. New backups use AES-GCM so corrupted or
      // tampered files fail authentication before restore.
      encrypter = enc.Encrypter(
        enc.AES(enc.Key(key), mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );
      iv = enc.IV(base64Decode(ivStr));
    } else {
      throw FormatException('Unsupported backup algorithm: $algorithm');
    }
    final decrypted = encrypter.decrypt64(dataStr, iv: iv);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  } catch (_) {
    throw const BackupCryptoException(
      'Decryption failed (wrong password or corrupted file)',
      wrongPassword: true,
    );
  }
}

/// AES-256-GCM, tag appended on encrypt and verified on decrypt.
Uint8List _gcm(bool encrypt, Uint8List key, Uint8List nonce, Uint8List input) {
  final cipher = pc.GCMBlockCipher(pc.AESEngine())
    ..init(encrypt,
        pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0)));
  return cipher.process(input);
}

/// PBKDF2-HMAC-SHA256.
Uint8List deriveBackupKey(String password, List<int> salt, int iterations) {
  final params = pc.Pbkdf2Parameters(
    Uint8List.fromList(salt),
    iterations,
    _keyLengthBytes,
  );
  final derivator = pc.PBKDF2KeyDerivator(
    pc.HMac(pc.SHA256Digest(), 64),
  )..init(params);
  return derivator.process(Uint8List.fromList(utf8.encode(password)));
}

Uint8List _randomBytes(int length) {
  final rand = Random.secure();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = rand.nextInt(256);
  }
  return bytes;
}
