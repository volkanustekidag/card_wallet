import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/widgets/card_search_bar.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/widgets/mini_iban_card_widget.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card_page.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_card_utils.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_qr_generator.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';

class IbanCardsBody extends StatefulWidget {
  final IbanCardController controller;

  const IbanCardsBody({super.key, required this.controller});

  @override
  State<IbanCardsBody> createState() => _IbanCardsBodyState();
}

class _IbanCardsBodyState extends State<IbanCardsBody> {
  String _searchQuery = '';
  CardSortOption _sortOption = CardSortOption.newest;

  IbanCardController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const PaddingConstants.extraHigh(),
      child: Obx(() {
        if (controller.ibanCards.isEmpty) {
          return const EmptyListInfo(
            ctaRoute: '/addIbanCard',
            ctaLabel: 'addFirstIC',
            ctaIcon: Icons.account_balance,
          );
        }

        final filtered = _filterAndSort(controller.ibanCards.toList());

        return Column(
          children: [
            CardSearchBar(
              query: _searchQuery,
              sort: _sortOption,
              onQueryChanged: (q) => setState(() => _searchQuery = q),
              onSortChanged: (s) => setState(() => _sortOption = s),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _buildNoSearchResults(context)
                  : ListView.builder(
                      clipBehavior: Clip.none,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ibanCard = filtered[index];
                        return MiniIbanCardWidget(
                          key: ValueKey(ibanCard.id),
                          ibanCard: ibanCard,
                          onCopyTap: () => _copyIBAN(context, ibanCard),
                          onQRTap: () =>
                              _checkPremiumAndShowQR(context, ibanCard),
                          onLongPress: () =>
                              _showCardActionsBottomSheet(context, ibanCard),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  List<IbanCard> _filterAndSort(List<IbanCard> cards) {
    final filtered = _searchQuery.trim().isEmpty
        ? List<IbanCard>.from(cards)
        : cards.where((c) => _matchesQuery(c, _searchQuery)).toList();

    switch (_sortOption) {
      case CardSortOption.newest:
        filtered.sort((a, b) => compareNewestFirst(
              aCreatedAt: a.createdAt,
              aId: a.id,
              bCreatedAt: b.createdAt,
              bId: b.id,
            ));
        break;
      case CardSortOption.oldest:
        filtered.sort((a, b) => compareNewestFirst(
              aCreatedAt: b.createdAt,
              aId: b.id,
              bCreatedAt: a.createdAt,
              bId: a.id,
            ));
        break;
      case CardSortOption.nameAsc:
        filtered.sort((a, b) =>
            a.cardHolder.toLowerCase().compareTo(b.cardHolder.toLowerCase()));
        break;
      case CardSortOption.nameDesc:
        filtered.sort((a, b) =>
            b.cardHolder.toLowerCase().compareTo(a.cardHolder.toLowerCase()));
        break;
      case CardSortOption.bank:
        filtered.sort((a, b) =>
            a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase()));
        break;
    }
    return filtered;
  }

  bool _matchesQuery(IbanCard card, String query) {
    final q = query.toLowerCase();
    return card.bankName.toLowerCase().contains(q) ||
        card.cardHolder.toLowerCase().contains(q) ||
        card.iban.toLowerCase().replaceAll(' ', '').contains(q) ||
        (card.notes?.toLowerCase().contains(q) ?? false) ||
        (card.tags?.any((t) => t.toLowerCase().contains(q)) ?? false);
  }

  Widget _buildNoSearchResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'searchNoResults'.tr(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyIBAN(BuildContext context, IbanCard ibanCard) {
    Clipboard.setData(ClipboardData(text: ibanCard.iban));
    HapticFeedback.lightImpact();
    _showAutoHideSnackBar(context, 'ibanCopied'.tr());
  }

  void _checkPremiumAndShowQR(BuildContext context, IbanCard ibanCard) async {
    final premiumController = Get.find<PremiumController>();

    if (!premiumController.isPremium) {
      final shouldUpgrade = await Get.dialog<bool>(
        AlertDialog(
          title: Text('premiumFeatureLockedTitle'.tr()),
          content: Text('qrCodePremiumDescription'.tr()),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('maybeLater'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: Text('goPremium'.tr()),
            ),
          ],
        ),
      ) ?? false;

      if (shouldUpgrade) {
        Get.toNamed('/premium');
      }
      return;
    }

    _showQRGenerationDialog(context, ibanCard);
  }

  void _showAutoHideSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showCardActionsBottomSheet(BuildContext context, IbanCard ibanCard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
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
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    ibanCard.cardHolder,
                    style: TextStyle(fontFamily: 'Poppins', 
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    ibanCard.bankName,
                    style: TextStyle(fontFamily: 'Poppins', 
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Divider(height: 1),
                _buildActionTile(
                  context,
                  icon: Icons.copy,
                  title: 'copyIban'.tr(),
                  subtitle: 'copyIbanSubtitle'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _copyIBAN(context, ibanCard);
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.content_copy,
                  title: 'copyAllInfo'.tr(),
                  subtitle: 'copyAllInfoSubtitle'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(
                        text:
                            "${ibanCard.cardHolder}\n${ibanCard.iban}\n${ibanCard.swiftCode}\n${ibanCard.bankName}"));
                    _showAutoHideSnackBar(context, 'copyInfo'.tr());
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.qr_code,
                  title: 'showQrCode'.tr(),
                  subtitle: 'showQrCodeSubtitle'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    _checkPremiumAndShowQR(context, ibanCard);
                  },
                ),
                if (ibanCard.id != 1)
                  _buildActionTile(
                    context,
                    icon: Icons.edit,
                    title: 'editCard'.tr(),
                    subtitle: 'editCardSubtitle'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(
                        () => AddIbanCardPage(
                          ibanCard: ibanCard,
                        ),
                        binding: AddIbanCardBindings(),
                      );
                    },
                  ),
                Divider(height: 1),
                _buildActionTile(
                  context,
                  icon: Icons.delete,
                  title: 'deleteCard'.tr(),
                  subtitle: 'deleteCardSubtitle'.tr(),
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    showDialogDeleteData(context, () {
                      controller.removeIbanCard(ibanCard);
                      _showAutoHideSnackBar(context, 'deleteSuccess'.tr());
                    });
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? Colors.red
        : (isDark ? Colors.white : Color(0xFF1A1A1A));

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontFamily: 'Poppins', 
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontFamily: 'Poppins', 
          fontSize: 12,
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.7)
              : Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

  void _showQRGenerationDialog(BuildContext context, IbanCard ibanCard) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              'qrCodeGenerate'.tr(),
              style: TextStyle(fontFamily: 'Poppins', 
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
              // IBAN Info
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
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
                      SizedBox(height: 8),
                      Text(
                        '${ibanCard.cardHolder}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        '${ibanCard.bankName}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        '${ibanCard.iban}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Amount Input
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'amountOptional'.tr(),
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.monetization_on),
                  suffixText: 'currency'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12),

              // Reference Input
              TextField(
                controller: referenceController,
                decoration: InputDecoration(
                  labelText: 'referenceOptional'.tr(),
                  hintText: 'paymentDescription'.tr(),
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLength: 35,
              ),
              SizedBox(height: 8),

              // Info Text
              Container(
                padding: EdgeInsets.all(12),
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
                    SizedBox(width: 8),
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
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(fontFamily: 'Poppins', 
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // Parse amount
              double? amount;
              if (amountController.text.isNotEmpty) {
                amount =
                    double.tryParse(amountController.text.replaceAll(',', '.'));
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
              style: TextStyle(fontFamily: 'Poppins', 
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
      // IBAN QR kod verisi oluştur
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

      // QR kod oluştur (otomatik format seçimi)
      final qrResult = IBANQRGenerator.generateQRCode(paymentData);

      if (qrResult.success && qrResult.data != null) {
        // Başarılı QR kod oluşturuldu
        _showQROptions(context, ibanCard, qrResult, reference: reference);
      } else {
        // QR kod oluşturma hatası
        _showQRError(context, qrResult.errors ?? ['QR kod oluşturulamadı']);
      }
    } catch (e) {
      // Genel hata
      _showQRError(context, ['${'qrGenerationError'.tr()} $e']);
    }
  }

  void _showQROptions(
      BuildContext context, IbanCard ibanCard, QRResult qrResult,
      {String? reference}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
            SizedBox(height: 16),

            // Title
            Text(
              'qrCodeOptions'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 4),
            Text(
              qrResult.metadata?.standard ?? 'TR-KAREKOD',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
            ),
            SizedBox(height: 24),

            // Options
            Row(
              children: [
                Expanded(
                  child: _buildQROptionButton(
                    context,
                    icon: Icons.visibility,
                    title: 'dialog'.tr(),
                    subtitle: 'dialogSubtitle'.tr(),
                    onPressed: () {
                      Navigator.pop(context);
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
                SizedBox(width: 12),
                Expanded(
                  child: _buildQROptionButton(
                    context,
                    icon: Icons.open_in_full,
                    title: 'bottomSheet'.tr(),
                    subtitle: 'bottomSheetSubtitle'.tr(),
                    onPressed: () {
                      Navigator.pop(context);
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
            SizedBox(height: 12),

            // Full screen option
            SizedBox(
              width: double.infinity,
              child: _buildQROptionButton(
                context,
                icon: Icons.fullscreen,
                title: 'fullScreen'.tr(),
                subtitle: 'fullScreenSubtitle'.tr(),
                onPressed: () {
                  Navigator.pop(context);
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

            SizedBox(height: 20),
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
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon,
                  size: 32,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700]),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'qrCodeError'.tr(),
              style: TextStyle(fontFamily: 'Poppins', 
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
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8),
            ...errors.map((error) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $error',
                    style: TextStyle(fontFamily: 'Poppins', 
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'ok'.tr(),
              style: TextStyle(fontFamily: 'Poppins', 
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showDialogDeleteData(
      BuildContext context, Function onConfirm) async {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: 'deleteIbanCard'.tr(),
          content: 'deleteDataMessage'.tr(),
          onConfirm: () {
            onConfirm();
            Get.back();
          },
        );
      },
    );
  }
}
