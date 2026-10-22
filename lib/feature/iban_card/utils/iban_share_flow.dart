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
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

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
  final choice =
      await showIbanShareSheet(context, isPremium: isPremium, card: card);
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

/// "Share as image" (primary, with a live preview of the image) and
/// "Share as text", plus "Add QR (Premium)" for free users.
Future<IbanShareChoice?> showIbanShareSheet(
  BuildContext context, {
  required bool isPremium,
  IbanCard? card,
}) {
  return showCwSheet<IbanShareChoice>(
    context,
    builder: (sheetContext) {
      final c = CwColors.of(sheetContext);
      void pick(IbanShareChoice choice) =>
          Navigator.of(sheetContext).pop(choice);
      final withQr = isPremium && card != null &&
          ShareableIbanCard.paymentQrData(card) != null;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'cwShareBankDetails'.tr(),
                style: CwType.title.copyWith(color: c.ink, fontSize: 20),
              ),
              if (card != null) ...[
                const SizedBox(height: 14),
                // The exact image that will be shared, scaled down.
                ClipRRect(
                  borderRadius: BorderRadius.circular(CwRadius.l),
                  child: AspectRatio(
                    aspectRatio: ShareableIbanCard.width /
                        ShareableIbanCard.sizeFor(withQr: withQr).height,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox.fromSize(
                        size: ShareableIbanCard.sizeFor(withQr: withQr),
                        child: ShareableIbanCard(
                          card: card,
                          qrData: withQr
                              ? ShareableIbanCard.paymentQrData(card)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CwButton(
                      'cwShareAsImage'.tr(),
                      key: const ValueKey('ibanShareImage'),
                      icon: CwIcons.photos,
                      height: 50,
                      onPressed: () => pick(IbanShareChoice.image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CwButton.secondary(
                      'cwShareAsText'.tr(),
                      key: const ValueKey('ibanShareText'),
                      icon: CwIcons.document,
                      height: 50,
                      onPressed: () => pick(IbanShareChoice.text),
                    ),
                  ),
                ],
              ),
              if (!isPremium) ...[
                const SizedBox(height: 10),
                CwGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    CwRow(
                      key: const ValueKey('ibanShareAddQr'),
                      leading: CwIconTile(CwIcons.qr, color: c.accent),
                      title: 'cwAddQrPremium'.tr(),
                      trailing: CwPill.accent(sheetContext, 'cwPremium'.tr(),
                          icon: CwIcons.gem),
                      onTap: () => pick(IbanShareChoice.addQrPremium),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
