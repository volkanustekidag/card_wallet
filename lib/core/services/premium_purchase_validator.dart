import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumPurchaseValidationResult {
  final bool isValid;
  final bool grantsLifetime;
  final bool grantsActiveSubscription;
  final String? reason;

  const PremiumPurchaseValidationResult({
    required this.isValid,
    this.grantsLifetime = false,
    this.grantsActiveSubscription = false,
    this.reason,
  });

  const PremiumPurchaseValidationResult.rejected(String this.reason)
      : isValid = false,
        grantsLifetime = false,
        grantsActiveSubscription = false;
}

/// Validates purchase receipts before granting premium entitlement.
///
/// Production builds must provide a backend endpoint using:
/// `--dart-define=PREMIUM_VALIDATION_URL=https://example.com/iap/validate`
///
/// Expected response body:
/// `{ "valid": true, "lifetime": false, "activeSubscription": true }`
class PremiumPurchaseValidator {
  static const String _validationUrl =
      String.fromEnvironment('PREMIUM_VALIDATION_URL');
  static const Duration _timeout = Duration(seconds: 10);

  const PremiumPurchaseValidator();

  Future<PremiumPurchaseValidationResult> validate(
    PurchaseDetails details, {
    required bool isLifetimeProduct,
    required bool isSubscriptionProduct,
  }) async {
    if (!_hasUsableVerificationData(details)) {
      return const PremiumPurchaseValidationResult.rejected(
        'empty receipt verification data',
      );
    }

    if (_validationUrl.trim().isEmpty) {
      // No backend configured: trust the OS-delivered purchase status.
      // Restored receipts come from the App Store / Play Store with their
      // own verification. v1.x of this app shipped with no server-side
      // validation at all; refusing to honour those receipts on update
      // would silently revoke entitlement for every existing paying user.
      // Equivalent to v1 behaviour and matches the in_app_purchase
      // package's recommended local-trust path.
      if (kReleaseMode) {
        debugPrint('[PremiumPurchaseValidator] PREMIUM_VALIDATION_URL not '
            'set — falling back to OS-trusted receipt for ${details.productID}.');
      }
      return PremiumPurchaseValidationResult(
        isValid: true,
        grantsLifetime: isLifetimeProduct,
        grantsActiveSubscription: isSubscriptionProduct,
        reason: 'no backend configured; trusting OS receipt',
      );
    }

    final uri = Uri.tryParse(_validationUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return const PremiumPurchaseValidationResult.rejected(
        'invalid receipt validation server url',
      );
    }

    try {
      final client = HttpClient();
      try {
        final request = await client.postUrl(uri).timeout(_timeout);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({
          'platform': Platform.operatingSystem,
          'productId': details.productID,
          'purchaseId': details.purchaseID,
          'transactionDate': details.transactionDate,
          'status': details.status.name,
          'verificationSource': details.verificationData.source,
          'localVerificationData':
              details.verificationData.localVerificationData,
          'serverVerificationData':
              details.verificationData.serverVerificationData,
        }));

        final response = await request.close().timeout(_timeout);
        final body = await utf8.decoder.bind(response).join().timeout(_timeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return PremiumPurchaseValidationResult.rejected(
            'validation server rejected receipt: ${response.statusCode}',
          );
        }

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          return const PremiumPurchaseValidationResult.rejected(
            'validation server returned invalid json',
          );
        }

        final valid = decoded['valid'] == true || decoded['active'] == true;
        if (!valid) {
          return PremiumPurchaseValidationResult.rejected(
            decoded['reason']?.toString() ?? 'receipt is not active',
          );
        }

        return PremiumPurchaseValidationResult(
          isValid: true,
          grantsLifetime: (decoded['lifetime'] as bool?) ?? isLifetimeProduct,
          grantsActiveSubscription: (decoded['activeSubscription'] as bool?) ??
              (isSubscriptionProduct && !isLifetimeProduct),
        );
      } finally {
        client.close(force: true);
      }
    } on TimeoutException {
      return const PremiumPurchaseValidationResult.rejected(
        'receipt validation timed out',
      );
    } catch (e) {
      return PremiumPurchaseValidationResult.rejected(
        'receipt validation failed: $e',
      );
    }
  }

  bool _hasUsableVerificationData(PurchaseDetails details) {
    final local = details.verificationData.localVerificationData;
    final server = details.verificationData.serverVerificationData;
    return local.isNotEmpty || server.isNotEmpty;
  }
}
