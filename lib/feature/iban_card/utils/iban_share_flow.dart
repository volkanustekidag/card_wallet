import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/utils/premium_gate.dart';
import 'package:wallet_app/core/utils/share_origin.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/feature/iban_card/widgets/shareable_iban_card.dart';

enum IbanShareChoice { text, image, addQrPremium }

/// Share an IBAN as text or as a card image. The image is free; premium
/// users get the payment QR on it, free users get it without QR plus an
/// "Add QR (Premium)" row that opens the `qrCreate` paywall.
///
/// [qrData] overrides the generated payment QR (e.g. a QR the user just
/// created with an amount); it is only used for premium users.
Future<void> shareIban(
  BuildContext context,
  IbanCard card, {
  String? qrData,
}) async {
  HapticFeedback.lightImpact();
  final isPremium = _isPremium();
  final choice = await showIbanShareSheet(context, isPremium: isPremium);
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case IbanShareChoice.text:
      AnalyticsService.instance.logCardShared(
        cardType: AnalyticsCardType.iban,
        masked: false,
        format: AnalyticsShareFormat.text,
        withQr: false,
      );
      await shareText(
        ibanShareText(card),
        origin: shareOriginFromContext(context),
      );
    case IbanShareChoice.image:
      final qr = isPremium
          ? (qrData ?? ShareableIbanCard.paymentQrData(card))
          : null;
      AnalyticsService.instance.logCardShared(
        cardType: AnalyticsCardType.iban,
        masked: false,
        format: AnalyticsShareFormat.image,
        withQr: qr != null,
      );
      final logo = await ShareableIbanCard.precacheBankLogo(context, card);
      if (!context.mounted) return;
      // shareWidgetAsImage runs the share sheet inside AppLockService.guard.
      final shared = await shareWidgetAsImage(
        context: context,
        widget: ShareableIbanCard(card: card, qrData: qr, bankLogoImage: logo),
        size: ShareableIbanCard.sizeFor(withQr: qr != null),
        filename: 'iban.png',
      );
      if (!shared && context.mounted) {
        context.showErrorSnackBar('shareImageFailed');
      }
    case IbanShareChoice.addQrPremium:
      openPremiumGate('qrCreate');
  }
}

/// Plain-text IBAN share body.
String ibanShareText(IbanCard card) =>
    '${card.bankName}\nIBAN: ${card.iban}\n${card.cardHolder}';

bool _isPremium() => Get.isRegistered<PremiumController>()
    ? Get.find<PremiumController>().isPremium
    : PremiumService.isPremium;

/// "Share as text" / "Share as image" (+ "Add QR (Premium)" for free users).
Future<IbanShareChoice?> showIbanShareSheet(
  BuildContext context, {
  required bool isPremium,
}) {
  return showModalBottomSheet<IbanShareChoice>(
    context: context,
    // Sized to its content and scrollable, so three rows still fit on short
    // screens and with large text.
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      void pick(IbanShareChoice choice) =>
          Navigator.of(sheetContext).pop(choice);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'shareIbanTitle'.tr(),
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                key: const ValueKey('ibanShareText'),
                leading: Icon(Icons.notes_rounded, color: colorScheme.primary),
                title: Text(
                  'shareAsText'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('shareAsTextSubtitle'.tr()),
                onTap: () => pick(IbanShareChoice.text),
              ),
              ListTile(
                key: const ValueKey('ibanShareImage'),
                leading: Icon(Icons.image_rounded, color: colorScheme.primary),
                title: Text(
                  'shareAsImage'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isPremium
                      ? 'shareAsImageWithQrSubtitle'.tr()
                      : 'shareAsImageSubtitle'.tr(),
                ),
                onTap: () => pick(IbanShareChoice.image),
              ),
              if (!isPremium)
                ListTile(
                  key: const ValueKey('ibanShareAddQr'),
                  leading: const Icon(
                    Icons.qr_code_rounded,
                    color: Color(0xFFC8A14A),
                  ),
                  title: Text(
                    'shareAddQrPremium'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('shareAddQrPremiumSubtitle'.tr()),
                  trailing: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFC8A14A),
                  ),
                  onTap: () => pick(IbanShareChoice.addQrPremium),
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text('cancel'.tr()),
              ),
            ],
          ),
        ),
      );
    },
  );
}
