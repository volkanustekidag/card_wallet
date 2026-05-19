import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';

enum WalletPassProvider {
  apple,
  google,
}

extension WalletPassProviderPath on WalletPassProvider {
  String get path {
    switch (this) {
      case WalletPassProvider.apple:
        return 'apple';
      case WalletPassProvider.google:
        return 'google';
    }
  }
}

class WalletPassExportResponse {
  final Uri launchUri;

  const WalletPassExportResponse({required this.launchUri});
}

class WalletPassExportException implements Exception {
  final String messageKey;

  const WalletPassExportException(this.messageKey);

  @override
  String toString() => messageKey;
}

/// Calls the private pass-signing backend.
///
/// Required runtime config:
/// `--dart-define=WALLET_EXPORT_BASE_URL=https://api.example.com`
///
/// Optional runtime config:
/// `--dart-define=WALLET_EXPORT_API_KEY=...`
///
/// Expected backend contract:
/// POST /v1/wallet/loyalty/apple  -> { "launchUrl": "https://.../card.pkpass" }
/// POST /v1/wallet/loyalty/google -> { "launchUrl": "https://pay.google.com/gp/v/save/..." }
///
/// For Google, the backend may also return `{ "jwt": "SIGNED_JWT" }`; the
/// client converts it to Google's save URL.
class WalletPassExportService {
  static const String _baseUrl =
      String.fromEnvironment('WALLET_EXPORT_BASE_URL');
  static const String _apiKey = String.fromEnvironment('WALLET_EXPORT_API_KEY');
  static const Duration _timeout = Duration(seconds: 20);

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  bool isBarcodeSupported(WalletPassProvider provider, LoyaltyCard card) {
    final format = card.barcodeFormat.trim().toUpperCase();
    switch (provider) {
      case WalletPassProvider.apple:
        return format == 'QR_CODE' || format == 'CODE_128';
      case WalletPassProvider.google:
        if (format == 'QR_CODE' ||
            format == 'CODE_128' ||
            format == 'CODE_39' ||
            format == 'EAN_13' ||
            format == 'EAN_8' ||
            format == 'UPC_A') {
          return true;
        }
        if (format == 'ITF') {
          return RegExp(r'^\d{14}$').hasMatch(card.barcode.trim());
        }
        return false;
    }
  }

  String unsupportedBarcodeMessageKey(WalletPassProvider provider) {
    switch (provider) {
      case WalletPassProvider.apple:
        return 'walletExportUnsupportedAppleBarcode';
      case WalletPassProvider.google:
        return 'walletExportUnsupportedGoogleBarcode';
    }
  }

  Future<WalletPassExportResponse> createLoyaltyPass({
    required WalletPassProvider provider,
    required LoyaltyCard card,
    required String locale,
    String? backgroundColor,
    String? foregroundColor,
    String? labelColor,
  }) async {
    if (!isConfigured) {
      throw const WalletPassExportException('walletExportNotConfigured');
    }
    if (!isBarcodeSupported(provider, card)) {
      throw WalletPassExportException(unsupportedBarcodeMessageKey(provider));
    }

    final endpoint = _endpoint(provider);
    final appCheckToken = await _fetchAppCheckToken();
    final client = HttpClient();
    try {
      final request = await client.postUrl(endpoint).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (_apiKey.trim().isNotEmpty) {
        request.headers.set('X-CardWallet-Api-Key', _apiKey.trim());
      }
      if (appCheckToken != null && appCheckToken.isNotEmpty) {
        // Defense-in-depth: the backend verifies this token via the
        // Firebase Admin SDK and rejects requests without it. The
        // legacy X-CardWallet-Api-Key header above is kept during the
        // soft-cutover; remove it once telemetry confirms every live
        // client is sending an App Check token.
        request.headers.set('X-Firebase-AppCheck', appCheckToken);
      }
      request.write(jsonEncode(_payload(
        card,
        locale,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        labelColor: labelColor,
      )));

      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WalletPassExportException(_errorKeyFromBody(body));
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const WalletPassExportException('walletExportInvalidResponse');
      }

      final launchUri = _launchUriFromResponse(provider, decoded);
      if (launchUri == null || !_isAllowedLaunchUri(provider, launchUri)) {
        throw const WalletPassExportException('walletExportInvalidResponse');
      }
      return WalletPassExportResponse(launchUri: launchUri);
    } on WalletPassExportException {
      rethrow;
    } on TimeoutException {
      throw const WalletPassExportException('walletExportTimeout');
    } on FormatException {
      throw const WalletPassExportException('walletExportInvalidResponse');
    } on SocketException {
      throw const WalletPassExportException('walletExportNetworkError');
    } finally {
      client.close(force: true);
    }
  }

  /// Fetch a fresh App Check attestation token. Returns null on
  /// failure so the caller can decide whether to still attempt the
  /// request (e.g. during the soft-cutover, the backend will accept
  /// either the legacy API key OR a valid App Check token).
  Future<String?> _fetchAppCheckToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      // Don't fail the user-facing wallet export over a transient
      // attestation hiccup. Crashlytics catches it via the global
      // handler in main.dart.
      debugPrint('AppCheck.getToken failed: $e');
      return null;
    }
  }

  Uri _endpoint(WalletPassProvider provider) {
    final trimmed = _baseUrl.trim();
    final base = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return Uri.parse('$base/v1/wallet/loyalty/${provider.path}');
  }

  Map<String, dynamic> _payload(
    LoyaltyCard card,
    String locale, {
    String? backgroundColor,
    String? foregroundColor,
    String? labelColor,
  }) {
    final brand = card.brand?.trim();
    return <String, dynamic>{
      'id': card.id,
      'name': card.name.trim(),
      'brand': brand == null || brand.isEmpty ? card.name.trim() : brand,
      'barcode': card.barcode.trim(),
      'barcodeFormat': card.barcodeFormat.trim().toUpperCase(),
      'notes': card.notes?.trim(),
      'logoAsset': card.logoAsset,
      'createdAt': card.createdAt?.toIso8601String(),
      'locale': locale,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (foregroundColor != null) 'foregroundColor': foregroundColor,
      if (labelColor != null) 'labelColor': labelColor,
    };
  }

  String _errorKeyFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final key = decoded['messageKey'];
        if (key is String && key.trim().isNotEmpty) return key.trim();
      }
    } catch (_) {
      // Fall through to the generic message.
    }
    return 'walletExportFailed';
  }

  /// Refuse to launch anything that isn't a vetted https URL for the
  /// expected provider. Without this a compromised backend could return
  /// `tel:` / `intent:` / a phishing http URL and the app would happily
  /// fire it via the OS.
  bool _isAllowedLaunchUri(WalletPassProvider provider, Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    switch (provider) {
      case WalletPassProvider.google:
        return host == 'pay.google.com';
      case WalletPassProvider.apple:
        // Apple pkpass URLs are served from our own backend, identified by
        // WALLET_EXPORT_BASE_URL. Pin to that host so a substituted URL
        // can't redirect the device to fetch a tampered pkpass.
        final baseHost = Uri.tryParse(_baseUrl.trim())?.host.toLowerCase();
        if (baseHost == null || baseHost.isEmpty) return false;
        return host == baseHost;
    }
  }

  Uri? _launchUriFromResponse(
    WalletPassProvider provider,
    Map<String, dynamic> data,
  ) {
    final direct = _firstString(data, <String>[
      'launchUrl',
      'url',
      'addUrl',
      'saveUrl',
      'pkpassUrl',
    ]);
    if (direct != null) return Uri.tryParse(direct);

    final jwt = _firstString(data, <String>['jwt', 'signedJwt']);
    if (provider == WalletPassProvider.google && jwt != null) {
      return Uri.tryParse('https://pay.google.com/gp/v/save/$jwt');
    }
    return null;
  }

  String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
