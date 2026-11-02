import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/barcode_display_boost.dart';
import 'package:wallet_app/core/utils/share_origin.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_share_flow.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/typography.dart';

class IbanCardUtils {
  /// Full-screen QR of an IBAN (or a payment QR) to show someone's camera.
  static void showQRFullScreen(
    BuildContext context, {
    required String qrData,
    required String beneficiaryName,
    String? amount,
    String? currency,
    String? reference,
    String? format,
    IbanCard? card,
    String? shareQrData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QRFullScreenPage(
          qrData: qrData,
          beneficiaryName: beneficiaryName,
          amount: amount,
          currency: currency,
          card: card,
          shareQrData: shareQrData,
        ),
      ),
    );
  }
}

/// White stage with a big QR, the holder's name and the IBAN; brightness is
/// raised while it's open, like the loyalty barcode.
class QRFullScreenPage extends StatefulWidget {
  final String qrData;
  final String beneficiaryName;
  final String? amount;
  final String? currency;
  final IbanCard? card;
  final String? shareQrData;

  const QRFullScreenPage({
    Key? key,
    required this.qrData,
    required this.beneficiaryName,
    this.amount,
    this.currency,
    this.card,
    this.shareQrData,
  }) : super(key: key);

  @override
  State<QRFullScreenPage> createState() => _QRFullScreenPageState();
}

class _QRFullScreenPageState extends State<QRFullScreenPage> {
  @override
  void initState() {
    super.initState();
    BarcodeDisplayBoost.instance.acquire();
  }

  @override
  void dispose() {
    BarcodeDisplayBoost.instance.release();
    super.dispose();
  }

  void _share() {
    final card = widget.card;
    if (card != null) {
      shareIban(context, card, qrData: widget.shareQrData);
      return;
    }
    AnalyticsService.instance
        .logCardShared(cardType: AnalyticsCardType.iban, masked: false);
    shareText(
      widget.qrData,
      subject: '${'qrCodeSubject'.tr()} - ${widget.beneficiaryName}',
      origin: shareOriginFromContext(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111215);
    final size = MediaQuery.sizeOf(context).width * 0.72;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const CwIcon(CwIcons.close, color: ink),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'cwShare'.tr(),
                    onPressed: _share,
                    icon: const CwIcon(CwIcons.share, color: ink),
                  ),
                ],
              ),
              const Spacer(),
              QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(widget.beneficiaryName,
                    textAlign: TextAlign.center,
                    style: CwType.title.copyWith(color: ink)),
              ),
              if (widget.card != null) ...[
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(formatIban(widget.card!.iban),
                        style: CwType.mono(size: 15, color: ink)),
                  ),
                ),
              ],
              if (widget.amount != null && widget.amount!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${widget.amount} ${widget.currency ?? 'EUR'}',
                    style: CwType.headline
                        .copyWith(color: const Color(0xFF3B3E46))),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
