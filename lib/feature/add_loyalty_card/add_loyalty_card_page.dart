import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/widgets/notes_and_tags_section.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_formats.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_validator.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/card_photos.dart';
import 'package:wallet_app/feature/scanner/brand_picker_sheet.dart';
import 'package:wallet_app/feature/scanner/live_scanner_page.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/ui/card/loyalty_preview.dart';
import 'package:wallet_app/ui/card/material_picker.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/components/cw_form.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Add / edit a loyalty card by hand: any brand from any country — pick it
/// from the catalogue or just type your own name. The barcode can be typed
/// or scanned; its format is checked before saving.
class AddLoyaltyCardPage extends StatefulWidget {
  final LoyaltyCard? card;
  const AddLoyaltyCardPage({Key? key, this.card}) : super(key: key);

  @override
  State<AddLoyaltyCardPage> createState() => _AddLoyaltyCardPageState();
}

class _AddLoyaltyCardPageState extends State<AddLoyaltyCardPage> {
  late final AddLoyaltyCardController _c = Get.find<AddLoyaltyCardController>();
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _website = TextEditingController();

  /// The format was set on purpose (picked, scanned or an existing card's):
  /// typing the number no longer guesses it.
  late bool _formatSet = widget.card != null;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _c.initializeForEdit(widget.card!);
    } else {
      _c.initializeForCreate();
    }
    final card = _c.currentCard.value;
    _name.text = card.name;
    _barcode.text = card.barcode;
    _website.text = card.website ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _website.dispose();
    super.dispose();
  }

  /// Strips scheme / www. / path so we save a bare domain ("metro.com.tr").
  /// Returns null if the input doesn't look like a domain.
  static String? normalizeDomain(String raw) {
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

  void _applyBrand(BrandEntry? b) {
    final previous = _c.currentCard.value.brand;
    _c.updateField('brand', b?.name);
    _c.updateField('brandColor', b?.color);
    if (b != null) {
      _website.text = b.domain;
      _c.updateField('website', b.domain);
      if (_name.text.trim().isEmpty || _name.text.trim() == previous) {
        _name.text = b.name;
        _c.updateField('name', b.name);
      }
    }
  }

  Future<void> _pickBrand() async {
    final picked = await showBrandPicker(context, initial: _name.text);
    if (picked == null || !mounted) return;
    _applyBrand(picked.clear ? null : picked.brand);
  }

  Future<void> _scan() async {
    final hit = await Navigator.of(context).push<ScanHit>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const LiveScannerPage(
        initialMode: ScanMode.barcode,
        returnHit: true,
      ),
    ));
    if (hit is! LoyaltyHit || !mounted) return;
    _barcode.text = hit.raw;
    _c.updateField('barcode', hit.raw);
    _c.updateField('barcodeFormat', hit.format);
    _formatSet = true;
    if (hit.brand != null && _c.currentCard.value.brand == null) {
      _applyBrand(hit.brand);
    }
  }

  Future<void> _pickFormat() async {
    final current = _c.currentCard.value.barcodeFormat;
    final picked = await showCwSheet<String>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: CwGroup(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              for (final f in kLoyaltyBarcodeFormats)
                CwRow(
                  title: f.label,
                  trailing: f.code == current
                      ? CwIcon(CwIcons.check, color: CwColors.of(sheet).accent)
                      : null,
                  onTap: () => Navigator.pop(sheet, f.code),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      _formatSet = true;
      _c.updateField('barcodeFormat', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final card = _c.currentCard.value;
      final editing = _c.isEditMode.value;
      final check = card.barcode.trim().isEmpty
          ? null
          : LoyaltyBarcodeValidator.validate(card.barcode, card.barcodeFormat);
      final suggestion = check == null || check.isValid
          ? null
          : LoyaltyBarcodeValidator.suggestFormat(
              card.barcode, card.barcodeFormat);
      return CwFormScaffold(
        title: editing ? 'cwEditCard'.tr() : 'cwNewLoyalty'.tr(),
        action: CwHeaderAction(
            icon: CwIcons.scan, label: 'cwScan'.tr(), onTap: _scan),
        preview: LoyaltyCardPreview(card: card),
        button: CwButton(
          editing ? 'cwSave'.tr() : 'cwAddCard'.tr(),
          loading: _c.isLoading.value,
          onPressed: _c.isFormValid && !_c.isLoading.value
              ? () => _c.saveCard()
              : null,
        ),
        children: [
          CwField(
            controller: _name,
            label: 'cwName'.tr(),
            hint: 'cwCardNameHint'.tr(),
            autofocus: !editing,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            onChanged: (v) => _c.updateField('name', v),
          ),
          const SizedBox(height: 10),
          _BrandRow(
            brand: card.brand,
            onTap: _pickBrand,
          ),
          const SizedBox(height: 10),
          CwField(
            controller: _barcode,
            label: 'cwBarcodeNumber'.tr(),
            mono: true,
            maxLength: 120,
            onChanged: (v) {
              _c.updateField('barcode', v.trim());
              // A valid EAN/UPC number is almost always printed as one.
              if (!_formatSet) {
                _c.updateField('barcodeFormat',
                    LoyaltyBarcodeValidator.guessFormat(v.trim()));
              }
            },
          ),
          const SizedBox(height: 10),
          CwGroup(
            margin: EdgeInsets.zero,
            children: [
              CwRow(
                title: 'cwBarcodeType'.tr(),
                value: barcodeFormatLabel(card.barcodeFormat),
                chevron: true,
                onTap: _pickFormat,
              ),
            ],
          ),
          if (check != null) ...[
            const SizedBox(height: 10),
            check.isValid
                ? CwNotice.ok(context,
                    '${barcodeFormatLabel(card.barcodeFormat)} · ${'cwVerified'.tr()}')
                : _InvalidNotice(
                    reason: describeBarcodeIssue(check, card.barcodeFormat),
                    suggestion: suggestion,
                    onUseSuggestion: suggestion == null
                        ? null
                        : () => _c.updateField('barcodeFormat', suggestion),
                  ),
          ],
          CwSectionHeader('cwCardPhotos'.tr(),
              padding: const EdgeInsets.fromLTRB(4, 22, 4, 8)),
          CardPhotoSlots(
            front: card.frontPhoto,
            back: card.backPhoto,
            onFront: (id) => _c.setPhoto(front: true, id: id),
            onBack: (id) => _c.setPhoto(front: false, id: id),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              card.barcode.trim().isEmpty && card.frontPhoto != null
                  ? 'cwPhotoInsteadOfBarcode'.tr()
                  : 'cwCardPhotosHint'.tr(),
              style: CwType.footnote.copyWith(color: CwColors.of(context).mute),
            ),
          ),
          const SizedBox(height: 18),
          MaterialPicker(
            selected: card.colorId,
            brandColor: BrandCatalog.instance.match(card.brand)?.color ??
                card.brandColor,
            brandSelected: card.brandColor != null,
            onBrand: () => _c.updateField(
                'brandColor',
                BrandCatalog.instance.match(card.brand)?.color ??
                    card.brandColor),
            onSelected: (i) {
              _c.updateField('colorId', i);
              _c.updateField('brandColor', null);
            },
          ),
          const SizedBox(height: 14),
          CwField(
            controller: _website,
            label: 'cwWebsite'.tr(),
            hint: 'example.com',
            icon: CwIcons.globe,
            keyboardType: TextInputType.url,
            onChanged: (v) => _c.updateField('website', normalizeDomain(v)),
          ),
          CwSectionHeader('cwNotesTags'.tr(),
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 8)),
          NotesAndTagsSection(
            initialNotes: card.notes,
            initialTags: card.tags,
            onNotesChanged: (v) => _c.updateField('notes', v),
            onTagsChanged: (v) => _c.updateField('tags', v),
          ),
          const SizedBox(height: 20),
          CwTrustLine('cwEncryptedLocal'.tr()),
          const SizedBox(height: 4),
        ],
      );
    });
  }
}

class _BrandRow extends StatelessWidget {
  final String? brand;
  final VoidCallback onTap;
  const _BrandRow({required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final matched = BrandCatalog.instance.match(brand) != null;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(CwRadius.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(CwRadius.m),
        onTap: onTap,
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
                      brand == null || brand!.isEmpty
                          ? 'cwChooseBrand'.tr()
                          : matched
                              ? '$brand · ${'cwMatchedCatalog'.tr()}'
                              : brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CwType.body
                          .copyWith(color: brand == null ? c.mute : c.ink),
                    ),
                  ],
                ),
              ),
              Text('cwChange'.tr(),
                  style: CwType.callout
                      .copyWith(color: c.accent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvalidNotice extends StatelessWidget {
  final String? reason;
  final String? suggestion;
  final VoidCallback? onUseSuggestion;

  const _InvalidNotice({
    required this.reason,
    required this.suggestion,
    required this.onUseSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CwNotice.warn(context, reason ?? 'cwFormatInvalid'.tr(),
            title: 'cwFormatInvalid'.tr()),
        if (suggestion != null && onUseSuggestion != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onUseSuggestion,
              child: Text(
                'loyaltyBarcodeUseFormat'
                    .tr(namedArgs: {'format': barcodeFormatLabel(suggestion!)}),
                style: CwType.callout
                    .copyWith(color: c.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
