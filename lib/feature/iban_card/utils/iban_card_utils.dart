import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/styles/app_themes.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';
import 'package:wallet_app/core/utils/share_origin.dart';

/// QR Code Display Utilities
class IbanCardUtils {
  /// QR kodu dialog olarak göster
  static void showQRDialog(
    BuildContext context, {
    required String qrData,
    required String beneficiaryName,
    String? amount,
    String? currency,
    String? reference,
    String? format,
    bool showDetails = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return QRDialog(
          qrData: qrData,
          beneficiaryName: beneficiaryName,
          amount: amount,
          currency: currency,
          reference: reference,
          format: format,
          showDetails: showDetails,
        );
      },
    );
  }

  /// QR kodu bottom sheet olarak göster
  static void showQRBottomSheet(
    BuildContext context, {
    required String qrData,
    required String beneficiaryName,
    String? amount,
    String? currency,
    String? reference,
    String? format,
    bool showDetails = true,
    bool isDraggable = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: isDraggable,
      builder: (BuildContext context) {
        return QRBottomSheet(
          qrData: qrData,
          beneficiaryName: beneficiaryName,
          amount: amount,
          currency: currency,
          reference: reference,
          format: format,
          showDetails: showDetails,
        );
      },
    );
  }

  /// QR kodu tam ekran göster
  static void showQRFullScreen(
    BuildContext context, {
    required String qrData,
    required String beneficiaryName,
    String? amount,
    String? currency,
    String? reference,
    String? format,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRFullScreenPage(
          qrData: qrData,
          beneficiaryName: beneficiaryName,
          amount: amount,
          currency: currency,
          reference: reference,
          format: format,
        ),
      ),
    );
  }
}

/// QR Dialog Widget
class QRDialog extends StatelessWidget {
  final String qrData;
  final String beneficiaryName;
  final String? amount;
  final String? currency;
  final String? reference;
  final String? format;
  final bool showDetails;

  const QRDialog({
    Key? key,
    required this.qrData,
    required this.beneficiaryName,
    this.amount,
    this.currency,
    this.reference,
    this.format,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'qrCode'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                gapless: false,
                errorStateBuilder: (cxt, err) {
                  return Container(
                    child: Center(
                      child: Text(
                        "errorGeneratingQR".tr(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),

            if (showDetails) ...[
              const SizedBox(height: 20),
              // Payment Details
              _buildPaymentDetails(context),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.copy,
                  label: 'copyQRAction'.tr(),
                  onPressed: () => _copyToClipboard(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.share,
                  label: 'shareQRAction'.tr(),
                  onPressed: () => _shareQR(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.fullscreen,
                  label: 'fullScreenAction'.tr(),
                  onPressed: () {
                    Navigator.of(context).pop();
                    IbanCardUtils.showQRFullScreen(
                      context,
                      qrData: qrData,
                      beneficiaryName: beneficiaryName,
                      amount: amount,
                      currency: currency,
                      reference: reference,
                      format: format,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('paymentDetails'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              )),
          const SizedBox(height: 12),
          _buildDetailRow(context, 'recipient'.tr(), beneficiaryName),
          if (amount != null && amount!.isNotEmpty)
            _buildDetailRow(
                context, 'amountLabel'.tr(), '$amount ${currency ?? 'EUR'}'),
          if (reference != null && reference!.isNotEmpty)
            _buildDetailRow(context, 'referenceLabel'.tr(), reference!),
          if (format != null)
            _buildDetailRow(
                context, 'formatLabel'.tr(), format!.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    SensitiveClipboard.copy(qrData);
    context.showSuccessSnackBar('qrCodeCopied');
  }

  void _shareQR(BuildContext context) {
    Share.share(
      qrData,
      subject: '${'qrCodeSubject'.tr()} - $beneficiaryName',
      sharePositionOrigin: shareOriginFromContext(context),
    );
  }
}

/// QR Bottom Sheet Widget
class QRBottomSheet extends StatelessWidget {
  final String qrData;
  final String beneficiaryName;
  final String? amount;
  final String? currency;
  final String? reference;
  final String? format;
  final bool showDetails;

  const QRBottomSheet({
    Key? key,
    required this.qrData,
    required this.beneficiaryName,
    this.amount,
    this.currency,
    this.reference,
    this.format,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final successColor = AppThemes.success(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'qrCodeGenerated'.tr(),
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.check,
                        color: successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // QR Code (always white — needed for scannability)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              if (showDetails) ...[
                const SizedBox(height: 30),
                _buildPaymentDetailsCard(context),
              ],
              const SizedBox(height: 30),
              _buildActionButtons(context),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetailsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'paymentInformation'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailTile(
                context, Icons.person, 'recipient'.tr(), beneficiaryName),
            if (amount != null && amount!.isNotEmpty)
              _buildDetailTile(context, Icons.monetization_on,
                  'amountLabel'.tr(), '$amount ${currency ?? 'EUR'}'),
            if (reference != null && reference!.isNotEmpty)
              _buildDetailTile(
                  context, Icons.tag, 'referenceLabel'.tr(), reference!),
            if (format != null)
              _buildDetailTile(context, Icons.qr_code, 'formatLabel'.tr(),
                  format!.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
      BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copyToClipboard(context),
            icon: const Icon(Icons.copy),
            label: Text('copy'.tr()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareQR(context),
            icon: const Icon(Icons.share),
            label: Text('share'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    SensitiveClipboard.copy(qrData);
    context.showSuccessSnackBar('qrCodeCopied');
  }

  void _shareQR(BuildContext context) {
    Share.share(
      qrData,
      subject: '${'qrCodeSubject'.tr()} - $beneficiaryName',
      sharePositionOrigin: shareOriginFromContext(context),
    );
  }
}

/// QR Full Screen Page
class QRFullScreenPage extends StatelessWidget {
  final String qrData;
  final String beneficiaryName;
  final String? amount;
  final String? currency;
  final String? reference;
  final String? format;

  const QRFullScreenPage({
    Key? key,
    required this.qrData,
    required this.beneficiaryName,
    this.amount,
    this.currency,
    this.reference,
    this.format,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareQR(context),
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: MediaQuery.of(context).size.width * 0.7,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 30),

            // Beneficiary Name
            Text(
              beneficiaryName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            if (amount != null && amount!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '$amount ${currency ?? 'EUR'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareQR(BuildContext context) {
    Share.share(
      qrData,
      subject: '${'qrCodeSubject'.tr()} - $beneficiaryName',
      sharePositionOrigin: shareOriginFromContext(context),
    );
  }
}

/// Kullanım Örneği Widget
class QRGeneratorExample extends StatefulWidget {
  @override
  _QRGeneratorExampleState createState() => _QRGeneratorExampleState();
}

class _QRGeneratorExampleState extends State<QRGeneratorExample> {
  final TextEditingController ibanController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  void _generateAndShowQR() {
    // QR kod oluştur (burada IBANQRGenerator kullanın)
    final qrData =
        "sample_qr_data"; // Gerçekte IBANQRGenerator.generateQRCode() sonucu

    // Dialog olarak göster
    IbanCardUtils.showQRDialog(
      context,
      qrData: qrData,
      beneficiaryName: nameController.text,
      amount: amountController.text,
      currency: 'EUR',
      reference: 'REF-001',
      format: 'IBAN QR',
    );
  }

  void _generateAndShowBottomSheet() {
    final qrData = "sample_qr_data";

    // Bottom Sheet olarak göster
    IbanCardUtils.showQRBottomSheet(
      context,
      qrData: qrData,
      beneficiaryName: nameController.text,
      amount: amountController.text,
      currency: 'EUR',
      reference: 'REF-001',
      format: 'IBAN QR',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('qrGeneratorDemo'.tr())),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ibanController,
              decoration: InputDecoration(labelText: 'ibanFieldLabel'.tr()),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'recipientNameLabel'.tr()),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'amountFieldLabel'.tr()),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generateAndShowQR,
                    child: Text('showDialog'.tr()),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generateAndShowBottomSheet,
                    child: Text('showBottomSheet'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
