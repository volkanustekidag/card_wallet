import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
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
        centerTitle: true,
        actions: [
          Obx(() {
            final canSave =
                _controller.isFormValid && !_controller.isLoading.value;
            return TextButton(
              onPressed: canSave ? _controller.saveCard : null,
              child: Text(
                'save'.tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: canSave
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreview(),
              const SizedBox(height: 24),
              _buildBrandPresets(),
              const SizedBox(height: 16),
              _textField(
                controller: _nameController,
                label: 'loyaltyCardNameLabel'.tr(),
                icon: Icons.badge_outlined,
                onChanged: (v) => _controller.updateField('name', v),
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _brandController,
                label: 'loyaltyCardBrandLabel'.tr(),
                icon: Icons.storefront_outlined,
                onChanged: (v) =>
                    _controller.updateField('brand', v.isEmpty ? null : v),
              ),
              const SizedBox(height: 12),
              _textField(
                controller: _barcodeController,
                label: 'loyaltyCardBarcodeLabel'.tr(),
                icon: Icons.qr_code_2_rounded,
                onChanged: (v) => _controller.updateField('barcode', v),
                helperText: 'loyaltyCardBarcodeHelper'.tr(),
              ),
              const SizedBox(height: 12),
              _buildBarcodeFormatDropdown(),
              const SizedBox(height: 12),
              _textField(
                controller: _notesController,
                label: 'notesLabel'.tr(),
                icon: Icons.notes_rounded,
                maxLines: 3,
                onChanged: (v) =>
                    _controller.updateField('notes', v.isEmpty ? null : v),
              ),
              const SizedBox(height: 24),
              _buildColorPicker(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'loyaltyScannerComingSoon'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final canSave =
                      _controller.isFormValid && !_controller.isLoading.value;
                  return ElevatedButton(
                    onPressed: canSave ? _controller.saveCard : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.card != null
                          ? 'updateAction'.tr()
                          : 'addAction'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Obx(() {
      final card = _controller.currentCard.value;
      final gradients = LinearGradients().linearGradientList;
      final gradient =
          gradients[card.colorId.clamp(0, gradients.length - 1)];
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
            Text(
              card.name.isEmpty
                  ? 'loyaltyCardNamePlaceholder'.tr()
                  : card.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (card.brand?.isNotEmpty ?? false) ? card.brand! : '—',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
    String? helperText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBarcodeFormatDropdown() {
    return Obx(() {
      final selected = _controller.currentCard.value.barcodeFormat;
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'loyaltyCardFormatLabel'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: kLoyaltyBarcodeFormats
                .map((f) => DropdownMenuItem(
                      value: f.code,
                      child: Text(
                        f.label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _controller.updateField('barcodeFormat', value);
              }
            },
          ),
        ),
      );
    });
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
          Text(
            'colorLabel'.tr(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gradients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == selected;
                final locked =
                    !isPremium && GradientCatalogue.isPremium(index);
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
                        color: isSelected ? Colors.black : Colors.transparent,
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
