import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// Last store-verified premium entitlement.
class CachedEntitlement {
  final String productId;
  final DateTime verifiedAt;

  const CachedEntitlement({required this.productId, required this.verifiedAt});

  bool isFresh(DateTime now, Duration ttl) =>
      !verifiedAt.isAfter(now) && now.difference(verifiedAt) < ttl;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'verifiedAt': verifiedAt.toUtc().toIso8601String(),
      };

  static CachedEntitlement? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final productId = map['productId'];
      final verifiedAt = DateTime.tryParse('${map['verifiedAt']}');
      if (productId is! String || productId.isEmpty || verifiedAt == null) {
        return null;
      }
      return CachedEntitlement(productId: productId, verifiedAt: verifiedAt);
    } catch (_) {
      return null;
    }
  }
}

/// Keeps the last verified entitlement in the Keychain / EncryptedSharedPrefs
/// so a paying user isn't shown as free (and bounced to the paywall) for the
/// few seconds — or the whole offline session — before the store answers.
///
/// It only ever grants premium *optimistically* for [ttl]; the store's
/// answer always wins. Editing the entry on a rooted device buys at most
/// [ttl] of premium until the next online launch.
class PremiumEntitlementCache {
  PremiumEntitlementCache({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageProvider.instance;

  static const Duration ttl = Duration(hours: 72);
  static const String _key = 'premium_entitlement_v1';

  final FlutterSecureStorage _storage;

  Future<CachedEntitlement?> read() async {
    try {
      return CachedEntitlement.tryParse(await _storage.read(key: _key));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CachedEntitlement entitlement) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(entitlement.toJson()));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
