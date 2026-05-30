import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_scanner_service.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_number_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_valid_thru_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/colors_list_view.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/widgets/notes_and_tags_section.dart';
import 'package:wallet_app/core/widgets/notification_permission_banner.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/add_credit_card/utils/upper_case_formatter.dart';

class CreditTextFieldForms extends StatefulWidget {
  /// Optional focus node for the card-number field. The add page passes
  /// one in so it can react to focus gains by expanding the live preview
  /// — same pattern as the IBAN page's IBAN field.
  final FocusNode? cardNumberFocusNode;

  const CreditTextFieldForms({Key? key, this.cardNumberFocusNode})
      : super(key: key);

  @override
  State<CreditTextFieldForms> createState() => _CreditTextFieldFormsState();
}

class _CreditTextFieldFormsState extends State<CreditTextFieldForms> {
  late final AddCreditCardController controller;
  late final CreditCardScannerService _scannerService;

  // TextEditingController'lar
  late final TextEditingController bankNameController;
  late final TextEditingController cardNumberController;
  late final TextEditingController cardHolderController;
  late final TextEditingController expirationController;
  late final TextEditingController paymentDueDayController;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AddCreditCardController>();
    _scannerService = CreditCardScannerService();

    // Controller'ları başlat
    bankNameController = TextEditingController();
    cardNumberController = TextEditingController();
    cardHolderController = TextEditingController();
    expirationController = TextEditingController();
    paymentDueDayController = TextEditingController();

    // Initial değerleri set et
    _updateTextFields();

    // currentCard değişikliklerini dinle
    ever(controller.currentCard, (_) => _updateTextFields());

    // Home sayfasındaki "Scan Card" tile'ı bu sayfayı autoScan: true ile
    // açıyor — sayfa yüklenir yüklenmez kamera scanner'ını tetikle.
    final args = Get.arguments;
    if (args is Map && args['autoScan'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scanCreditCard();
      });
    }
  }

  void _updateTextFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final card = controller.currentCard.value;

        // Only push controller text when it actually differs — otherwise
        // setting `controller.text = controller.text` collapses the
        // selection to the end and the cursor jumps mid-typing.
        if (bankNameController.text != card.bankName) {
          bankNameController.text = card.bankName;
        }
        if (cardNumberController.text != card.creditCardNumber) {
          cardNumberController.text = card.creditCardNumber;
        }
        if (cardHolderController.text != card.cardHolder) {
          cardHolderController.text = card.cardHolder;
        }
        if (expirationController.text != card.expirationDate) {
          expirationController.text = card.expirationDate;
        }
        final paymentDueDay = card.paymentDueDay?.toString() ?? '';
        if (paymentDueDayController.text != paymentDueDay) {
          paymentDueDayController.text = paymentDueDay;
        }
      }
    });
  }

  // Kamera ile kart tarama
  Future<void> _scanCreditCard() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scannedInfo = await _scannerService.scanCreditCard();

      if (scannedInfo != null) {
        // Taranan bilgileri form'a yansıt
        if (scannedInfo['cardNumber']?.isNotEmpty == true) {
          cardNumberController.text = scannedInfo['cardNumber']!;
          controller.updateCardField(
              "creditCardNumber", scannedInfo['cardNumber']!);
        }

        if (scannedInfo['expiryDate']?.isNotEmpty == true) {
          expirationController.text = scannedInfo['expiryDate']!;
          controller.updateCardField(
              "expirationDate", scannedInfo['expiryDate']!);
        }

        if (scannedInfo['cardHolder']?.isNotEmpty == true) {
          cardHolderController.text = scannedInfo['cardHolder']!;
          controller.updateCardField("cardHolder", scannedInfo['cardHolder']!);
        }

        context.showSuccessSnackBar('creditCardScannedSuccessfully');
      }
    } catch (e) {
      context.showErrorSnackBar('failedToScanCreditCard');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Galeriden fotoğraf seçme
  Future<void> _scanFromGallery() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scannedInfo = await _scannerService.scanFromGallery();

      if (scannedInfo != null) {
        // Taranan bilgileri form'a yansıt
        if (scannedInfo['cardNumber']?.isNotEmpty == true) {
          cardNumberController.text = scannedInfo['cardNumber']!;
          controller.updateCardField(
              "creditCardNumber", scannedInfo['cardNumber']!);
        }

        if (scannedInfo['expiryDate']?.isNotEmpty == true) {
          expirationController.text = scannedInfo['expiryDate']!;
          controller.updateCardField(
              "expirationDate", scannedInfo['expiryDate']!);
        }

        if (scannedInfo['cardHolder']?.isNotEmpty == true) {
          cardHolderController.text = scannedInfo['cardHolder']!;
          controller.updateCardField("cardHolder", scannedInfo['cardHolder']!);
        }

        context.showSuccessSnackBar('creditCardScannedSuccessfully');
      }
    } catch (e) {
      context.showErrorSnackBar('failedToScanCreditCard');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Tarama seçenekleri dialog'u
  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'scanCreditCard'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: colorScheme.primary),
                title: Text('takePhoto'.tr()),
                subtitle: Text('takePhotoSubtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _scanCreditCard();
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library, color: colorScheme.secondary),
                title: Text('choosePhotoFromGallery'.tr()),
                subtitle: Text('choosePhotoSubtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _scanFromGallery();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _handleScanButtonPressed() {
    // Scanner free for everyone — gating it gates the "wow" moment that
    // gets users invested. The 2-card free cap is what funnels upgrades.
    _showScanOptions();
  }

  @override
  void dispose() {
    bankNameController.dispose();
    cardNumberController.dispose();
    cardHolderController.dispose();
    expirationController.dispose();
    paymentDueDayController.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScanButton(theme),
        const SizedBox(height: 24),
        _buildBankField(context),
        const SizedBox(height: 20),
        TextFieldCard(
          controller: cardNumberController,
          focusNode: widget.cardNumberFocusNode,
          maxLength: 19,
          onChanged: _onCardNumberChanged,
          label: "cardNumberLabel".tr(),
          hintText: "0000 0000 0000 0000",
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CardNumberFormatter(),
          ],
          iconData: Icons.credit_card_rounded,
          textInputType: TextInputType.number,
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface,
          ),
          emphasize: true,
        ),
        const SizedBox(height: 16),
        TextFieldCard(
          controller: cardHolderController,
          maxLength: 24,
          onChanged: (val) {
            final upper = val.toUpperCase();
            if (cardHolderController.text != upper) {
              cardHolderController.value = TextEditingValue(
                text: upper,
                selection: TextSelection.collapsed(offset: upper.length),
              );
            }
            controller.updateCardField("cardHolder", upper);
          },
          label: "cardholderLabel".tr(),
          hintText: "cardHolderPlaceholder".tr(),
          inputFormatters: [UpperCaseTextFormatter()],
          iconData: Icons.person_outline,
          textInputType: TextInputType.name,
        ),
        const SizedBox(height: 20),
        TextFieldCard(
          controller: expirationController,
          maxLength: 7,
          onChanged: (val) {
            controller.updateCardField("expirationDate", val);
          },
          label: "expiryLabel".tr(),
          hintText: "MM / YY",
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[\d\s/]'),
            ),
            CardValidThruFormatter(),
          ],
          iconData: Icons.date_range,
          textInputType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: _withOpacity(theme.colorScheme.onSurface, 0.58),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'cvcNotStored'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _withOpacity(theme.colorScheme.onSurface, 0.62),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => _buildReminderSection(theme)),
        const SizedBox(height: 24),
        _buildColorPickerSection(theme),
        const SizedBox(height: 24),
        NotesAndTagsSection(
          initialNotes: controller.currentCard.value.notes,
          initialTags: controller.currentCard.value.tags,
          onNotesChanged: (val) => controller.updateCardField('notes', val),
          onTagsChanged: (val) => controller.updateCardField('tags', val),
        ),
        const SizedBox(height: 24),
        Text(
          "secureStorageInfo".tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: _withOpacity(theme.colorScheme.onSurface, 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton(ThemeData theme) {
    final borderColor = _withOpacity(theme.colorScheme.primary, 0.2);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isScanning ? null : _handleScanButtonPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          side: BorderSide(color: borderColor),
          backgroundColor: _withOpacity(theme.colorScheme.primary, 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const SizedBox.shrink(),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "scanCardOptional".tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            _isScanning
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.document_scanner_outlined,
                    color: theme.colorScheme.primary,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankField(BuildContext context) {
    return TextFieldCard(
      controller: bankNameController,
      maxLength: 24,
      onChanged: (val) {
        controller.updateCardField("bankName", val);
      },
      label: "bName".tr(),
      hintText: "unknownBank".tr(),
      inputFormatters: null,
      iconData: Icons.account_balance_outlined,
      textInputType: TextInputType.text,
    );
  }

  void _onCardNumberChanged(String val) {
    controller.updateCardField("creditCardNumber", val);
    // Card number is the source of truth: whenever the BIN matches a known
    // bank, overwrite the bank field. The field stays editable so the user
    // can tweak the name afterwards — but as soon as they touch the card
    // number again, autofill wins.
    final detected = CardBankDetector.detect(val);
    if (detected != null && bankNameController.text != detected) {
      bankNameController.text = detected;
      controller.updateCardField("bankName", detected);
    }
  }

  Widget _buildReminderSection(ThemeData theme) {
    final card = controller.currentCard.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cardRemindersTitle'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const NotificationPermissionBanner(
          margin: EdgeInsets.only(bottom: 12),
        ),
        _buildReminderSwitch(
          theme: theme,
          icon: Icons.event_available_outlined,
          title: 'expiryReminderLabel'.tr(),
          value: card.expiryReminderEnabled,
          onChanged: (value) {
            controller.updateCardField('expiryReminderEnabled', value);
          },
        ),
        if (card.expiryReminderEnabled) ...[
          const SizedBox(height: 10),
          _buildDaysBeforeChips(
            theme: theme,
            selectedValue: card.expiryReminderDaysBefore,
            values: const [7, 14, 30, 60],
            onSelected: (value) {
              controller.updateCardField('expiryReminderDaysBefore', value);
            },
          ),
        ],
        const SizedBox(height: 12),
        TextFieldCard(
          controller: paymentDueDayController,
          maxLength: 2,
          onChanged: _onPaymentDueDayChanged,
          label: 'paymentDueDayLabel'.tr(),
          hintText: '15',
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          iconData: Icons.calendar_month_outlined,
          textInputType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildReminderSwitch(
          theme: theme,
          icon: Icons.payments_outlined,
          title: 'paymentReminderLabel'.tr(),
          value: card.paymentReminderEnabled,
          onChanged: (value) {
            if (value && controller.currentCard.value.paymentDueDay == null) {
              paymentDueDayController.text = '15';
              controller.updateCardField('paymentDueDay', 15);
            }
            controller.updateCardField('paymentReminderEnabled', value);
          },
        ),
        if (card.paymentReminderEnabled) ...[
          const SizedBox(height: 10),
          _buildDaysBeforeChips(
            theme: theme,
            selectedValue: card.paymentReminderDaysBefore,
            values: const [0, 1, 3, 7],
            onSelected: (value) {
              controller.updateCardField('paymentReminderDaysBefore', value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildReminderSwitch({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        secondary: Icon(
          icon,
          color: value
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildDaysBeforeChips({
    required ThemeData theme,
    required int selectedValue,
    required List<int> values,
    required ValueChanged<int> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            selected: selectedValue == value,
            onSelected: (_) => onSelected(value),
            label: Text(
              value == 0
                  ? 'sameDayReminder'.tr()
                  : 'daysBeforeReminder'.tr(
                      namedArgs: {'days': value.toString()},
                    ),
            ),
            labelStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selectedValue == value
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            side: BorderSide(
              color: selectedValue == value
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }

  void _onPaymentDueDayChanged(String value) {
    if (value.isEmpty) {
      controller.updateCardField('paymentDueDay', null);
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      controller.updateCardField('paymentDueDay', null);
      return;
    }

    final safeValue = parsed.clamp(1, 31).toInt();
    if (safeValue != parsed) {
      final text = safeValue.toString();
      paymentDueDayController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    controller.updateCardField('paymentDueDay', safeValue);
  }

  Widget _buildColorPickerSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "cardColorOptional".tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "cardColorOptionalSubtitle".tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: _withOpacity(theme.colorScheme.onSurface, 0.6),
          ),
        ),
        const SizedBox(height: 12),
        const ColorsListView(),
      ],
    );
  }

  Color _withOpacity(Color color, double opacity) {
    final safeValue = opacity.clamp(0.0, 1.0);
    return color.withAlpha((safeValue * 255).round());
  }
}
