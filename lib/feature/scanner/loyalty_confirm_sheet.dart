import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_formats.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_validator.dart';
import 'package:wallet_app/feature/scanner/brand_picker_sheet.dart';
import 'package:wallet_app/ui/card/loyalty_preview.dart';
import 'package:wallet_app/ui/card/material_picker.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// "Looks good?" — confirm a scanned loyalty barcode: preview, name, brand
/// (matched from the catalogue when the card's text named one) and card
/// material. Saving goes through [AddLoyaltyCardController] so the barcode
/// check, the free-card limit and post-add prompts all still apply.
/// Returns true when the card was saved.
Future<bool> showLoyaltyConfirmSheet(
  BuildContext context, {
  required String raw,
  required String format,
  BrandEntry? brand,
}) async {
  // saveCard closes the sheet itself before it returns, so the sheet's
  // future completes first; the save's own result is what counts.
  Future<bool>? saving;
  await showCwSheet<void>(
    context,
    builder: (_) => _ConfirmBody(
      raw: raw,
      format: format,
      brand: brand,
      onSaving: (f) => saving = f,
    ),
  );
  return await (saving ?? Future.value(false));
}

class _ConfirmBody extends StatefulWidget {
  final String raw;
  final String format;
  final BrandEntry? brand;
  final ValueChanged<Future<bool>> onSaving;

  const _ConfirmBody({
    required this.raw,
    required this.format,
    required this.brand,
    required this.onSaving,
  });

  @override
  State<_ConfirmBody> createState() => _ConfirmBodyState();
}

class _ConfirmBodyState extends State<_ConfirmBody> {
  late final TextEditingController _name =
      TextEditingController(text: widget.brand?.name ?? '');
  late BrandEntry? _brand = widget.brand;
  late bool _useBrandColour = widget.brand != null;
  int _colorId = 0;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  LoyaltyCard get _draft => LoyaltyCard(
        id: 'draft',
        name: _name.text.trim(),
        brand: _brand?.name,
        barcode: widget.raw,
        barcodeFormat: widget.format,
        colorId: _colorId,
        website: _brand?.domain,
        brandColor: _useBrandColour ? _brand?.color : null,
      );

  Future<void> _pickBrand() async {
    final picked = await showBrandPicker(context, initial: _name.text);
    if (picked == null || !mounted) return;
    setState(() {
      if (picked.clear) {
        _brand = null;
        _useBrandColour = false;
      } else {
        final previous = _brand?.name;
        _brand = picked.brand;
        _useBrandColour = true;
        if (_name.text.trim().isEmpty || _name.text.trim() == previous) {
          _name.text = picked.brand!.name;
        }
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ctrl = Get.find<AddLoyaltyCardController>()..initializeForCreate();
    final d = _draft;
    ctrl
      ..updateField('name', d.name)
      ..updateField('brand', d.brand)
      ..updateField('barcode', d.barcode)
      ..updateField('barcodeFormat', d.barcodeFormat)
      ..updateField('colorId', d.colorId)
      ..updateField('website', d.website)
      ..updateField('brandColor', d.brandColor);
    // saveCard pops this sheet itself on success.
    final save = ctrl.saveCard();
    widget.onSaving(save);
    await save;
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final draft = _draft;
    final valid =
        LoyaltyBarcodeValidator.validate(widget.raw, widget.format).isValid;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('cwLooksGood'.tr(),
                      style: CwType.title.copyWith(color: c.ink, fontSize: 22)),
                ),
                valid
                    ? CwPill.ok(
                        context,
                        '${barcodeFormatLabel(widget.format)} · ${'cwVerified'.tr()}',
                        icon: CwIcons.check,
                      )
                    : CwPill.warn(context, 'cwFormatInvalid'.tr(),
                        icon: CwIcons.warning),
              ],
            ),
            const SizedBox(height: 14),
            LoyaltyCardPreview(card: draft),
            const SizedBox(height: 14),
            CwField(
              controller: _name,
              label: 'cwName'.tr(),
              hint: 'cwCardNameHint'.tr(),
              autofocus: widget.brand == null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(CwRadius.m),
              child: InkWell(
                borderRadius: BorderRadius.circular(CwRadius.m),
                onTap: _pickBrand,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('cwBrand'.tr(),
                                style: CwType.caption.copyWith(color: c.mute)),
                            const SizedBox(height: 2),
                            Text(
                              _brand == null
                                  ? 'cwChooseBrand'.tr()
                                  : '${_brand!.name} · ${'cwMatchedCatalog'.tr()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CwType.body.copyWith(
                                  color: _brand == null ? c.mute : c.ink),
                            ),
                          ],
                        ),
                      ),
                      Text('cwChange'.tr(),
                          style: CwType.callout.copyWith(
                              color: c.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            MaterialPicker(
              selected: _colorId,
              brandColor: _brand?.color,
              brandSelected: _useBrandColour && _brand != null,
              onBrand: () => setState(() => _useBrandColour = true),
              onSelected: (i) => setState(() {
                _colorId = i;
                _useBrandColour = false;
              }),
            ),
            const SizedBox(height: 18),
            CwButton(
              'cwAddToWallet'.tr(),
              loading: _saving,
              onPressed: _name.text.trim().isEmpty || _saving ? null : _save,
            ),
            const SizedBox(height: 12),
            CwTrustLine('cwOnDevice'.tr(), icon: CwIcons.lock),
          ],
        ),
      ),
    );
  }
}
