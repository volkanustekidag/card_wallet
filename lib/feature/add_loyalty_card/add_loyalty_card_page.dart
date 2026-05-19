import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_barcode_scanner_service.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/core/widgets/primary_form_button.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_formats.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_brand_presets.dart';

class AddLoyaltyCardPage extends StatefulWidget {
  final LoyaltyCard? card;
  const AddLoyaltyCardPage({Key? key, this.card}) : super(key: key);

  @override
  State<AddLoyaltyCardPage> createState() => _AddLoyaltyCardPageState();
}

class _AddLoyaltyCardPageState extends State<AddLoyaltyCardPage> {
  late final AddLoyaltyCardController _controller;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _notesController;
  late final TextEditingController _websiteController;
  late final LoyaltyBarcodeScannerService _scannerService;
  bool _isScanning = false;
  bool _websiteExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AddLoyaltyCardController>();
    if (widget.card != null) {
      _controller.initializeForEdit(widget.card!);
    } else {
      _controller.initializeForCreate();
    }
    final c = _controller.currentCard.value;
    _nameController = TextEditingController(text: c.name);
    _brandController = TextEditingController(text: c.brand ?? '');
    _barcodeController = TextEditingController(text: c.barcode);
    _notesController = TextEditingController(text: c.notes ?? '');
    _websiteController = TextEditingController(text: c.website ?? '');
    _websiteExpanded = (c.website ?? '').isNotEmpty;
    _scannerService = LoyaltyBarcodeScannerService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    _websiteController.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  /// Strips scheme / www. / path so we save a bare domain ("metro.com.tr").
  /// Returns null if the input doesn't look like a domain.
  static String? _normalizeDomain(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    s = s.replaceFirst(RegExp(r'^https?://'), '');
    s = s.replaceFirst(RegExp(r'^www\.'), '');
    final slash = s.indexOf('/');
    if (slash >= 0) s = s.substring(0, slash);
    if (!s.contains('.')) return null;
    if (s.endsWith('.')) return null;
    if (!RegExp(r'^[a-z0-9.\-]+$').hasMatch(s)) return null;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          widget.card != null
              ? 'editLoyaltyCardTitle'.tr()
              : 'addLoyaltyCardTitle'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBar: StickyBottomBar(
        child: Obx(() {
          final isBusy = _controller.isLoading.value;
          final canSave = _controller.isFormValid && !isBusy;
          return PrimaryFormButton(
            label: widget.card != null ? 'updateAction'.tr() : 'addAction'.tr(),
            isBusy: isBusy,
            onPressed: canSave ? _controller.saveCard : null,
          );
        }),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPreview(),
              ),
              const SizedBox(height: 24),
              _buildBrandPresets(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFieldCard(
                  controller: _nameController,
                  label: '${'loyaltyCardNameLabel'.tr()} *',
                  iconData: Icons.badge_outlined,
                  onChanged: (v) => _controller.updateField('name', v),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFieldCard(
                  controller: _brandController,
                  label: 'loyaltyCardBrandLabel'.tr(),
                  iconData: Icons.storefront_outlined,
                  onChanged: (v) =>
                      _controller.updateField('brand', v.isEmpty ? null : v),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildWebsiteSection(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final card = _controller.currentCard.value;
                  final digitsOnly =
                      isDigitOnlyBarcodeFormat(card.barcodeFormat);
                  return TextFieldCard(
                    controller: _barcodeController,
                    label: '${'loyaltyCardBarcodeLabel'.tr()} *',
                    iconData: Icons.qr_code_2_rounded,
                    onChanged: (v) => _controller.updateField('barcode', v),
                    helperText: 'loyaltyCardBarcodeHelper'.tr(),
                    errorText: _barcodeError(card.barcode, card.barcodeFormat),
                    textInputType:
                        digitsOnly ? TextInputType.number : TextInputType.text,
                    inputFormatters: digitsOnly
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                  );
                }),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildScanButton(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBarcodeFormatTile(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFieldCard(
                  controller: _notesController,
                  label: 'notesLabel'.tr(),
                  iconData: Icons.notes_rounded,
                  maxLines: 3,
                  onChanged: (v) =>
                      _controller.updateField('notes', v.isEmpty ? null : v),
                ),
              ),
              const SizedBox(height: 24),
              _buildColorPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebsiteSection() {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    if (!_websiteExpanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _websiteExpanded = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_link_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  'loyaltyWebsiteAdd'.tr(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Obx(() {
      final card = _controller.currentCard.value;
      final resolved = (card.website ?? '').isNotEmpty;
      return TextFieldCard(
        controller: _websiteController,
        label: 'loyaltyWebsiteLabel'.tr(),
        iconData: Icons.language_rounded,
        textInputType: TextInputType.url,
        helperText: resolved
            ? 'loyaltyWebsiteResolved'.tr(namedArgs: {'domain': card.website!})
            : 'loyaltyWebsiteHelper'.tr(),
        onChanged: (v) {
          final normalized = _normalizeDomain(v);
          _controller.updateField('website', normalized);
        },
      );
    });
  }

  Widget _buildScanButton() {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return OutlinedButton(
      onPressed: _isScanning ? null : _showScanOptions,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.35),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        foregroundColor: accent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _isScanning ? 'scanInProgress'.tr() : 'loyaltyScanBarcode'.tr(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: accent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isScanning) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  void _showScanOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'loyaltyScanBarcode'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.qr_code_scanner_rounded,
                    color: theme.colorScheme.primary),
                title: Text('loyaltyScanFromCamera'.tr()),
                subtitle: Text('loyaltyScanFromCameraSubtitle'.tr()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _runScan(fromCamera: true);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: theme.colorScheme.secondary),
                title: Text('chooseFromGallery'.tr()),
                subtitle: Text('loyaltyScanFromGallerySubtitle'.tr()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _runScan(fromCamera: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runScan({required bool fromCamera}) async {
    setState(() => _isScanning = true);
    try {
      final result = fromCamera
          ? await _scannerService.scanFromCamera()
          : await _scannerService.scanFromGallery();
      if (result == null) return;

      final value = result.rawValue;
      _barcodeController.text = value;
      _controller.updateField('barcode', value);

      if (result.format != null) {
        _controller.updateField('barcodeFormat', result.format!);
      }

      if (mounted) {
        context.showSuccessSnackBar('loyaltyBarcodeScanned');
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Widget _buildPreview() {
    return Obx(() {
      final card = _controller.currentCard.value;
      final gradients = LinearGradients().linearGradientList;
      final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (LoyaltyBrandResolver.domainFor(card.brand) != null ||
                    (card.website?.isNotEmpty ?? false)) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: BankLogo(
                      loyaltyBrand: card.brand,
                      domain: card.website,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.name.isEmpty
                            ? 'loyaltyCardNamePlaceholder'.tr()
                            : card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (card.brand?.isNotEmpty ?? false) ? card.brand! : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.barcode.isEmpty
                    ? 'loyaltyCardBarcodePlaceholder'.tr()
                    : card.barcode,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBrandPresets() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kLoyaltyBrandPresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final preset = kLoyaltyBrandPresets[index];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              _brandController.text = preset.name;
              _controller.updateField('brand', preset.name);
              if (_nameController.text.trim().isEmpty) {
                _nameController.text = preset.name;
                _controller.updateField('name', preset.name);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: preset.seedColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: preset.seedColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: preset.seedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    preset.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarcodeFormatTile() {
    return Obx(() {
      final theme = Theme.of(context);
      final selected = _controller.currentCard.value.barcodeFormat;
      final format = kLoyaltyBarcodeFormats.firstWhere(
        (f) => f.code == selected,
        orElse: () => kLoyaltyBarcodeFormats.first,
      );
      final fillColor =
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _showBarcodeFormatSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'loyaltyCardFormatLabel'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        format.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showBarcodeFormatSheet() {
    final theme = Theme.of(context);
    final selected = _controller.currentCard.value.barcodeFormat;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                'loyaltyCardFormatLabel'.tr(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final f in kLoyaltyBarcodeFormats)
                      ListTile(
                        title: Text(
                          f.label,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: f.code == selected
                            ? Icon(Icons.check_rounded,
                                color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          _controller.updateField('barcodeFormat', f.code);
                          Navigator.of(ctx).pop();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _barcodeError(String value, String format) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final expected = _expectedBarcodeLength(format);
    if (expected != null && trimmed.length != expected) {
      return 'loyaltyBarcodeLengthError'.tr(
        namedArgs: {'count': expected.toString()},
      );
    }
    if (format == 'ITF' && trimmed.length.isOdd) {
      return 'loyaltyBarcodeEvenLengthError'.tr();
    }
    return null;
  }

  int? _expectedBarcodeLength(String format) {
    switch (format) {
      case 'EAN_13':
        return 13;
      case 'EAN_8':
        return 8;
      case 'UPC_A':
        return 12;
      default:
        return null;
    }
  }

  Widget _buildColorPicker() {
    final gradients = LinearGradients().linearGradientList;
    final premium = Get.find<PremiumController>();
    return Obx(() {
      final selected = _controller.currentCard.value.colorId;
      final isPremium = premium.isPremium;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'colorLabel'.tr(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: gradients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == selected;
                final locked = !isPremium && GradientCatalogue.isPremium(index);
                return GestureDetector(
                  onTap: () {
                    if (locked) {
                      Get.toNamed('/premium');
                      return;
                    }
                    _controller.updateField('colorId', index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: gradients[index],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: locked
                        ? const Center(
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
