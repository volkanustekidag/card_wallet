import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/utils/iban_country_meta.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/core/widgets/card_search_bar.dart';
import 'package:wallet_app/core/widgets/tag_filter_chips.dart';
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
  Set<String> _selectedTags = {};

  IbanCardController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filtered = _filterAndSort(controller.ibanCards.toList());

      final allTags = collectAllTags(
        credits: const [],
        ibans: controller.ibanCards,
      );

      return Column(
        children: [
          CardSearchBar(
            query: _searchQuery,
            sort: _sortOption,
            onQueryChanged: (q) => setState(() => _searchQuery = q),
            onSortChanged: (s) => setState(() => _sortOption = s),
          ),
          if (allTags.isNotEmpty)
            TagFilterChips(
              tags: allTags,
              selected: _selectedTags,
              onChanged: (next) => setState(() => _selectedTags = next),
            ),
          Expanded(
            child: filtered.isEmpty
                ? _buildNoSearchResults(context)
                : ListView.builder(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.only(top: 4, bottom: 32),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ibanCard = filtered[index];
                      return MiniIbanCardWidget(
                        key: ValueKey(ibanCard.id),
                        ibanCard: ibanCard,
                        onTap: () =>
                            _showCardActionsBottomSheet(context, ibanCard),
                        onLongPress: () =>
                            _showCardActionsBottomSheet(context, ibanCard),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  List<IbanCard> _filterAndSort(List<IbanCard> cards) {
    Iterable<IbanCard> work = cards;
    if (_searchQuery.trim().isNotEmpty) {
      work = work.where((c) => _matchesQuery(c, _searchQuery));
    }
    if (_selectedTags.isNotEmpty) {
      work = work.where((c) {
        final cardTags = c.tags;
        if (cardTags == null || cardTags.isEmpty) return false;
        return _selectedTags.every(cardTags.contains);
      });
    }
    final filtered = work.toList();

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
                size: 56, color: colorScheme.onSurface.withValues(alpha: 0.4)),
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
          ) ??
          false;

      if (shouldUpgrade) {
        Get.toNamed('/premium');
      }
      return;
    }

    _showQRGenerationDialog(context, ibanCard);
  }

  void _showAutoHideSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCardActionsBottomSheet(BuildContext context, IbanCard ibanCard) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    ibanCard.cardHolder,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    ibanCard.bankName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
        );
      },
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
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final subtitleColor = isDestructive
        ? colorScheme.error.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtitleColor,
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
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.qr_code, color: colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'qrCodeGenerate'.tr(),
                style: const TextStyle(
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
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'accountInfo'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(ibanCard.cardHolder, style: textTheme.bodyMedium),
                        Text(ibanCard.bankName, style: textTheme.bodyMedium),
                        Text(ibanCard.iban, style: textTheme.bodyMedium),
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
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12),

                // Reference Input
                TextField(
                  controller: referenceController,
                  decoration: InputDecoration(
                    labelText: 'referenceOptional'.tr(),
                    hintText: 'paymentDescription'.tr(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLength: 35,
                ),
                SizedBox(height: 8),

                // Info Text
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'amountInfo'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
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
                foregroundColor: colorScheme.onSurfaceVariant,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'cancel'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                double? amount;
                if (amountController.text.isNotEmpty) {
                  amount = double.tryParse(
                      amountController.text.replaceAll(',', '.'));
                }
                _generateAndShowQR(
                  context,
                  ibanCard,
                  amount: amount,
                  reference: referenceController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'qrCodeGenerate'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
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
        currency: currencyForIban(ibanCard.iban),
        reference: reference ?? '',
        description:
            reference?.isNotEmpty == true ? reference : ibanCard.bankName,
      );

      // Format defaults to 'auto' so the generator picks TR-KAREKOD,
      // EPC SEPA, or ISO 20022 based on the IBAN's country.
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
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
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
                qrResult.metadata?.standard ?? 'IBAN QR',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
        );
      },
    );
  }

  Widget _buildQROptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
              Icon(icon, size: 32, color: colorScheme.onSurface),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
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
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: colorScheme.error),
              SizedBox(width: 8),
              Text(
                'qrCodeError'.tr(),
                style: const TextStyle(
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
                style: const TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              ...errors.map((error) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $error',
                      style: TextStyle(
                        color: colorScheme.error,
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
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'ok'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
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
