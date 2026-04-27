import 'package:easy_localization/easy_localization.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_qr_generator.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/widgets/background_shapes_painter.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/mini_iban_card_widget.dart';
import 'package:wallet_app/core/widgets/premium_crown_widget.dart';
import 'package:wallet_app/core/widgets/premium_upgrade_widget.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_card_utils.dart';
import 'package:wallet_app/feature/home/widgets/dashed_empty_card.dart';

class HomeBody extends StatelessWidget {
  final HomeController controller;

  const HomeBody({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final latestCreditCard =
          _getLatestCreditCard(controller.creditCards.toList());
      final latestIbanCard = _getLatestIbanCard(controller.ibanCards.toList());

      return SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundShapesPainter(),
              ),
            ),
            ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                AppBar(
                  elevation: 0,
                  centerTitle: true,
                  forceMaterialTransparency: true,
                  leading: IconButton(
                    icon: Icon(Icons.menu_rounded, size: 20.sp),
                    onPressed: () {
                      Get.toNamed('/settings')?.then(
                        (value) => controller.refreshData(),
                      );
                    },
                  ),
                  title: Text(
                    "CARDWALLET".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      letterSpacing: 0.005,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  actions: [
                    const PremiumCrownWidget(size: 20),
                  ],
                ),
                const PremiumUpgradeWidget(),
                const SizedBox(height: 16),
                _buildQuickAddShortcuts(context),
                const SizedBox(height: 16),
                if (latestCreditCard != null) ...[
                  _buildSectionHeaderRow(
                    context: context,
                    title: 'lastAddedCreditCard'.tr(),
                    actionLabel: 'seeAllCreditCardsAction'.tr(),
                    route: '/creditCards',
                  ),
                  const SizedBox(height: 8),
                  _buildCreditCardPreview(latestCreditCard),
                  const SizedBox(height: 32),
                ] else ...[
                  _buildSectionHeaderRow(
                    context: context,
                    title: 'lastAddedCreditCard'.tr(),
                    actionLabel: 'seeAllCreditCardsAction'.tr(),
                    route: '/creditCards',
                  ),
                  const SizedBox(height: 8),
                  DashedEmptyCard(
                    route: '/addCreditCard',
                    text: 'addCC'.tr(),
                  ),
                  const SizedBox(height: 32),
                ],
                if (latestIbanCard != null) ...[
                  _buildSectionHeaderRow(
                    context: context,
                    title: 'lastAddedIbanCard'.tr(),
                    actionLabel: 'seeAllIbanCardsAction'.tr(),
                    route: '/ibanCards',
                  ),
                  _buildIbanCardPreview(context, latestIbanCard),
                ] else ...[
                  _buildSectionHeaderRow(
                    context: context,
                    title: 'lastAddedIbanCard'.tr(),
                    actionLabel: 'seeAllIbanCardsAction'.tr(),
                    route: '/ibanCards',
                  ),
                  const SizedBox(height: 8),
                  DashedEmptyCard(
                    route: '/addIbanCard',
                    text: 'addIC'.tr(),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickAddShortcuts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickAddCard(
              context,
              title: "addCC".tr(),
              icon: Icons.credit_card,
              color: Colors.blue,
              route: "/addCreditCard",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickAddCard(
              context,
              title: "addIC".tr(),
              icon: Icons.account_balance,
              color: Colors.green,
              route: "/addIbanCard",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 72,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () async {
            // Kart limiti kontrolü
            final premiumController = Get.find<PremiumController>();

            if (route == "/addCreditCard") {
              final currentCount = await premiumController
                  .getStoredCardCount(CardLimitType.credit);
              if (!premiumController.canAddMoreCreditCards(currentCount)) {
                final canProceed =
                    await showCardLimitDialog(context, CardLimitType.credit);
                if (!canProceed) return;
              }
            } else if (route == "/addIbanCard") {
              final currentCount = await premiumController
                  .getStoredCardCount(CardLimitType.iban);
              if (!premiumController.canAddMoreIbanCards(currentCount)) {
                final canProceed =
                    await showCardLimitDialog(context, CardLimitType.iban);
                if (!canProceed) return;
              }
            }

            Get.toNamed(route)?.then(
              (value) => Get.find<HomeController>().refreshData(),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeaderRow({
    required BuildContext context,
    required String title,
    required String actionLabel,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => _handleSeeAllNavigation(route),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardPreview(CreditCard creditCard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1.58,
          child: FlipCard(
            direction: FlipDirection.HORIZONTAL,
            speed: 1000,
            front: CreditCardFront(creditCard: creditCard),
            back: CreditCardBack(creditCard: creditCard),
          ),
        ),
      ),
    );
  }

  Widget _buildIbanCardPreview(BuildContext context, IbanCard ibanCard) {
    return MiniIbanCardWidget(
      ibanCard: ibanCard,
      onCopyTap: () => _copyIBAN(context, ibanCard),
      onQRTap: () => _showQRGenerationDialog(context, ibanCard),
      onLongPress: () => _handleSeeAllNavigation('/ibanCards'),
    );
  }

  void _handleSeeAllNavigation(String route) {
    Get.toNamed(route)?.then((_) => controller.refreshData());
  }

  CreditCard? _getLatestCreditCard(List<CreditCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }

  IbanCard? _getLatestIbanCard(List<IbanCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }

  void _copyIBAN(BuildContext context, IbanCard ibanCard) {
    Clipboard.setData(ClipboardData(text: ibanCard.iban));
    HapticFeedback.lightImpact();
    _showAutoHideSnackBar(context, 'ibanCopied'.tr());
  }

  void _showAutoHideSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showQRGenerationDialog(BuildContext context, IbanCard ibanCard) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'qrCodeGenerate'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'accountInfo'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ibanCard.cardHolder,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        ibanCard.bankName,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        ibanCard.iban,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'amountOptional'.tr(),
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.monetization_on),
                  suffixText: 'currency'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referenceController,
                decoration: InputDecoration(
                  labelText: 'referenceOptional'.tr(),
                  hintText: 'paymentDescription'.tr(),
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLength: 35,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[900]?.withValues(alpha: 0.3)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue[600]!
                        : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue[400]
                          : Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'amountInfo'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[300]
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              double? amount;
              if (amountController.text.isNotEmpty) {
                amount = double.tryParse(
                  amountController.text.replaceAll(',', '.'),
                );
              }
              _generateAndShowQR(
                context,
                ibanCard,
                amount: amount,
                reference: referenceController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'qrCodeGenerate'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateAndShowQR(
    BuildContext context,
    IbanCard ibanCard, {
    double? amount,
    String? reference,
  }) {
    try {
      final paymentData = IBANQRGenerator.createPaymentData(
        iban: ibanCard.iban,
        beneficiaryName: ibanCard.cardHolder,
        amount: amount,
        currency: 'TRY',
        reference: reference ?? '',
        description: reference?.isNotEmpty == true
            ? reference
            : 'IBAN Kartı QR Kodu - ${ibanCard.bankName}',
      );

      final qrResult = IBANQRGenerator.generateQRCode(paymentData);

      if (qrResult.success && qrResult.data != null) {
        _showQROptions(context, ibanCard, qrResult, reference: reference);
      } else {
        _showQRError(context, qrResult.errors ?? ['qrCodeCannotGenerate'.tr()]);
      }
    } catch (e) {
      _showQRError(context, ['${'qrGenerationError'.tr()} $e']);
    }
  }

  void _showQROptions(
    BuildContext context,
    IbanCard ibanCard,
    QRResult qrResult, {
    String? reference,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'qrCodeOptions'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              qrResult.metadata?.standard ?? 'TR-KAREKOD',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQROptionButton(
                    context,
                    icon: Icons.visibility,
                    title: 'dialog'.tr(),
                    subtitle: 'dialogSubtitle'.tr(),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      IbanCardUtils.showQRDialog(
                        context,
                        qrData: qrResult.data!,
                        beneficiaryName: ibanCard.cardHolder,
                        amount: qrResult.metadata?.formattedAmount,
                        currency: qrResult.metadata?.currency,
                        reference: reference,
                        format: qrResult.metadata?.standard,
                        showDetails: true,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQROptionButton(
                    context,
                    icon: Icons.open_in_full,
                    title: 'bottomSheet'.tr(),
                    subtitle: 'bottomSheetSubtitle'.tr(),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      IbanCardUtils.showQRBottomSheet(
                        context,
                        qrData: qrResult.data!,
                        beneficiaryName: ibanCard.cardHolder,
                        amount: qrResult.metadata?.formattedAmount,
                        currency: qrResult.metadata?.currency,
                        reference: reference,
                        format: qrResult.metadata?.standard,
                        showDetails: true,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildQROptionButton(
                context,
                icon: Icons.fullscreen,
                title: 'fullScreen'.tr(),
                subtitle: 'fullScreenSubtitle'.tr(),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  IbanCardUtils.showQRFullScreen(
                    context,
                    qrData: qrResult.data!,
                    beneficiaryName: ibanCard.cardHolder,
                    amount: qrResult.metadata?.formattedAmount,
                    currency: qrResult.metadata?.currency,
                    reference: reference,
                    format: qrResult.metadata?.standard,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQROptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRError(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (errorContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'qrCodeError'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'qrCodeErrorMessage'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            ...errors.map(
              (error) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $error',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(errorContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'ok'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
