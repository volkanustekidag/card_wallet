import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// Photos of a card's front and back (membership cards with a picture,
/// cards whose barcode no scanner reads, info printed on the back).
///
/// Like the cards themselves they never leave the phone unencrypted: each
/// photo is one AES-256-GCM file (12-byte nonce + ciphertext) under the
/// app's support directory, keyed by a random id the card stores. The key
/// lives in the Keychain / Keystore, bound to this device.
class CardPhotoStore {
  CardPhotoStore._();
  static final CardPhotoStore instance = CardPhotoStore._();

  static const _keyName = 'card_photo_key_v1';
  static const _uuid = Uuid();

  /// Decrypted photos recently shown; the detail page and the editor open
  /// the same few again and again.
  final Map<String, Uint8List> _cache = {};
  static const _cacheSize = 8;

  Future<Uint8List>? _key;
  Directory? _dir;

  @visibleForTesting
  Directory? debugDirectory;

  Future<Directory> _directory() async {
    final d = debugDirectory ??
        (_dir ??= Directory(
            '${(await getApplicationSupportDirectory()).path}/card_photos'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Uint8List> _loadKey() => _key ??= () async {
        final storage = SecureStorageProvider.instance;
        final stored = await storage.read(key: _keyName);
        if (stored != null) return base64Decode(stored);
        final bytes = _random(32);
        await storage.write(key: _keyName, value: base64Encode(bytes));
        return bytes;
      }()
          .catchError((Object e) {
        _key = null;
        throw e;
      });

  File _file(Directory d, String id) => File('${d.path}/$id.bin');

  /// AES-256-GCM with a 128-bit tag appended to the ciphertext. PointyCastle
  /// directly: it verifies the tag on decrypt (the `encrypt` package's
  /// decryptBytes does not).
  static Uint8List _gcm(
      bool encrypt, Uint8List key, Uint8List iv, Uint8List input) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(encrypt, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(input);
  }

  static Uint8List _random(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
  }

  static bool _validId(String id) =>
      RegExp(r'^[a-zA-Z0-9-]{8,64}$').hasMatch(id);

  /// Stores [jpeg] and returns its new id.
  Future<String> save(Uint8List jpeg) async {
    final id = _uuid.v4();
    await write(id, jpeg);
    return id;
  }

  /// Stores [jpeg] under [id] (restore keeps the ids the cards refer to).
  Future<void> write(String id, Uint8List jpeg) async {
    if (!_validId(id)) throw ArgumentError('Bad photo id');
    final key = await _loadKey();
    final iv = _random(12);
    final out = BytesBuilder(copy: false)
      ..add(iv)
      ..add(_gcm(true, key, iv, jpeg));
    await _file(await _directory(), id)
        .writeAsBytes(out.takeBytes(), flush: true);
    _remember(id, jpeg);
  }

  /// The photo, or null when it is missing or can't be decrypted.
  Future<Uint8List?> load(String? id) async {
    if (id == null || !_validId(id)) return null;
    final hit = _cache[id];
    if (hit != null) return hit;
    try {
      final f = _file(await _directory(), id);
      if (!await f.exists()) return null;
      final raw = await f.readAsBytes();
      if (raw.length <= 12) return null;
      final key = await _loadKey();
      // Throws on a wrong key or a modified file (GCM tag check).
      final bytes = _gcm(false, key, raw.sublist(0, 12), raw.sublist(12));
      _remember(id, bytes);
      return bytes;
    } catch (e) {
      debugPrint('Card photo $id unreadable: $e');
      return null;
    }
  }

  Future<void> delete(String? id) async {
    if (id == null || !_validId(id)) return;
    _cache.remove(id);
    try {
      final f = _file(await _directory(), id);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Removes every photo not in [keep] (after a restore, or a card edit
  /// that replaced one).
  Future<void> keepOnly(Set<String> keep) async {
    try {
      final d = await _directory();
      await for (final f in d.list()) {
        if (f is! File || !f.path.endsWith('.bin')) continue;
        final name = f.uri.pathSegments.last;
        final id = name.substring(0, name.length - 4);
        if (!keep.contains(id)) {
          _cache.remove(id);
          await f.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> deleteAll() => keepOnly(const {});

  void _remember(String id, Uint8List bytes) {
    _cache.remove(id);
    _cache[id] = bytes;
    while (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  @visibleForTesting
  void debugReset() {
    _cache.clear();
    _key = null;
    _dir = null;
    debugDirectory = null;
  }
}
