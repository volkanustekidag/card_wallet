import 'package:get/get.dart';
import 'package:wallet_app/core/services/analytics_service.dart';

/// Opens the paywall for a premium-only feature the user just tapped and
/// records `premium_gate_tapped {feature}`. [feature] is one of the keys
/// PremiumPage understands (`walletExport`, `backupRestore`, `qrCreate`,
/// `unlimitedCards`) or `premiumColors`. Biometric unlock and IBAN scanning
/// (camera OCR, QR camera, QR from gallery) are free and never open the
/// paywall; creating an IBAN QR (`qrCreate`) stays Premium.
Future<T?>? openPremiumGate<T>(
  String feature, {
  Map<String, dynamic> extraArguments = const {},
}) {
  AnalyticsService.instance.logPremiumGateTapped(feature);
  return Get.toNamed<T>('/premium', arguments: {
    'feature': feature,
    'trigger': 'feature_gate',
    ...extraArguments,
  });
}
