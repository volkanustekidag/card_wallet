import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:uuid/uuid.dart';
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/core/data/storage/card_photo_store.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/feature/import/importers.dart';
import 'package:wallet_app/feature/import/photo_import.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_top_bar.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Import loyalty cards from Stocard (Klarna export), Catima, FidMe, Apple
/// Wallet passes or any CSV. Files are read on the device; nothing is
/// uploaded. The free-plan card limit applies exactly as for manual adds.
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  ImportResult? _result;
  final Set<int> _on = {};
  bool _busy = false;

  /// Photo import in progress: images read so far / picked.
  (int, int)? _reading;

  /// The "found" header: results scroll into view when they arrive.
  final _foundKey = GlobalKey();

  Future<void> _pickPhotos() async {
    if (_reading != null) return;
    final files = await PhotoImport.pick();
    if (files.isEmpty || !mounted) return;
    setState(() => _reading = (0, files.length));
    final cards = await PhotoImport.read(files, onProgress: (done) {
      if (mounted) setState(() => _reading = (done, files.length));
    });
    if (!mounted) return;
    setState(() => _reading = null);
    _show(ImportResult(ImportSource.photos, cards));
  }

  void _show(ImportResult r) {
    if (r.cards.isEmpty) {
      context.showInfoSnackBar('cwImportNothing');
      return;
    }
    setState(() {
      _result = r;
      _on
        ..clear()
        ..addAll([
          for (var i = 0; i < r.cards.length; i++)
            if (r.cards[i].usable) i,
        ]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _foundKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: CwMotion.base, curve: CwMotion.standard);
      }
    });
  }

  /// The chosen cards won't all fit the free plan: say so before the
  /// paywall does.
  bool _overFreeLimit() {
    if (!Get.isRegistered<PremiumController>()) return false;
    final premium = Get.find<PremiumController>();
    if (premium.isPremium) return false;
    final have = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().loyaltyCards.length
        : 0;
    return !premium.canAddMoreLoyaltyCards(have + _on.length - 1);
  }

  Future<void> _rename(int i) async {
    final r = _result;
    if (r == null) return;
    final ctrl = TextEditingController(text: r.cards[i].name);
    final name = await showCwSheet<String>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              18, 4, 18, 18 + MediaQuery.viewInsetsOf(sheet).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CwField(
                controller: ctrl,
                label: 'cwName'.tr(),
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (v) => Navigator.pop(sheet, v),
              ),
              const SizedBox(height: 14),
              CwButton('cwSave'.tr(),
                  onPressed: () => Navigator.pop(sheet, ctrl.text)),
            ],
          ),
        ),
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    setState(() {
      final cards = [...r.cards];
      cards[i] = cards[i].copyWith(name: name.trim());
      _result = ImportResult(r.source, cards);
    });
  }

  Future<void> _pick({bool stocardGuide = false}) async {
    if (stocardGuide) {
      final go = await _showStocardGuide();
      if (go != true) return;
    }
    FilePickerResult? picked;
    try {
      picked = await AppLockService.guard(() =>
          FilePicker.platform.pickFiles(type: FileType.any, withData: true));
    } catch (_) {
      picked = null;
    }
    final file = picked?.files.single;
    if (file == null || !mounted) return;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) return;
    await _parse(file.name, bytes);
  }

  Future<void> _parse(String name, Uint8List bytes, {String? password}) async {
    try {
      final r = Importers.parse(name, bytes, password: password);
      if (!mounted) return;
      _show(r);
    } on ImportNeedsPassword {
      if (!mounted) return;
      final pw = await _askPassword();
      if (pw != null && pw.isNotEmpty) await _parse(name, bytes, password: pw);
    } catch (_) {
      if (mounted) context.showErrorSnackBar('cwFileUnreadable');
    }
  }

  Future<String?> _askPassword() {
    final ctrl = TextEditingController();
    return showCwSheet<String>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('cwImportPassword'.tr(),
                  style: CwType.title
                      .copyWith(color: CwColors.of(sheet).ink, fontSize: 20)),
              const SizedBox(height: 14),
              CwField(
                controller: ctrl,
                label: 'cwPassword'.tr(),
                obscure: true,
                autofocus: true,
                onSubmitted: (v) => Navigator.pop(sheet, v),
              ),
              const SizedBox(height: 14),
              CwButton('cwOpen'.tr(),
                  onPressed: () => Navigator.pop(sheet, ctrl.text)),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showStocardGuide() => showCwSheet<bool>(
        context,
        builder: (sheet) {
          final c = CwColors.of(sheet);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('cwStocardGuideTitle'.tr(),
                      style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
                  const SizedBox(height: 10),
                  Text('cwStocardGuide'.tr(),
                      style: CwType.body.copyWith(color: c.ink2)),
                  const SizedBox(height: 18),
                  CwButton('cwChooseFile'.tr(),
                      onPressed: () => Navigator.pop(sheet, true)),
                ],
              ),
            ),
          );
        },
      );

  Future<void> _import() async {
    final r = _result;
    if (r == null || _on.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final service = LoyaltyCardService();
      await service.openBox();
      final chosen = [for (final i in _on.toList()..sort()) r.cards[i]];
      final premium = Get.find<PremiumController>();
      var count = await premium.getStoredCardCount(CardLimitType.loyalty);
      var allowed = chosen.length;
      for (var i = 0; i < chosen.length; i++) {
        if (!premium.canAddMoreLoyaltyCards(count + i)) {
          allowed = i;
          break;
        }
      }
      if (allowed < chosen.length && mounted) {
        final unlocked =
            await showCardLimitDialog(context, CardLimitType.loyalty);
        if (unlocked) allowed = chosen.length;
      }
      const uuid = Uuid();
      final now = DateTime.now();
      for (var i = 0; i < allowed; i++) {
        final card = chosen[i];
        final brand = BrandCatalog.instance.match(card.name);
        final photo = card.photoOnly
            ? await CardPhotoStore.instance.save(card.photo!)
            : null;
        await service.addLoyaltyCard(LoyaltyCard(
          frontPhoto: photo,
          id: uuid.v4(),
          name: card.name,
          brand: brand?.name,
          barcode: card.barcode,
          barcodeFormat: card.barcodeValid ? card.format : 'CODE_128',
          colorId: 0,
          notes: card.note,
          createdAt: now.subtract(Duration(seconds: i)),
          website: brand?.domain,
          brandColor: card.color ?? brand?.color,
          // Stocard's usage history seeds "Up Next" from day one.
          useCount: card.usedAt.isEmpty ? null : card.usedAt.length,
          lastUsedAt: card.usedAt.isEmpty ? null : card.usedAt.last,
          usageLog: card.usedAt.isEmpty
              ? null
              : [
                  for (final t in card.usedAt.reversed
                      .take(kUsageLogCap)
                      .toList()
                      .reversed)
                    t.millisecondsSinceEpoch
                ],
        ));
        count++;
      }
      AnalyticsService.instance
          .logCardsImported(source: r.source.name, count: allowed);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshData();
      }
      if (!mounted) return;
      if (allowed > 0) {
        context.showSuccessSnackBar('cwImported'.plural(allowed));
      }
      if (allowed < chosen.length) {
        context.showInfoSnackBar('cwImportLimitPartial');
      }
      if (allowed > 0) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) context.showErrorSnackBar('failedToSaveLoyaltyCard');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final r = _result;
    return CwPageStyle(
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CwScrollEdge(
                  bar: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: Row(
                      children: [
                        CwCircleButton(
                          CwIcons.back,
                          onPressed: () => Navigator.of(context).maybePop(),
                          semanticLabel: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                        ),
                        Expanded(
                          child: Text('cwImportTitle'.tr(),
                              textAlign: TextAlign.center,
                              style: CwType.headline.copyWith(color: c.ink)),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                  body: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
                        child: Text('cwImportHero'.tr(),
                            style: CwType.display
                                .copyWith(color: c.ink, fontSize: 28)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
                        child: Text('cwImportSub'.tr(),
                            style: CwType.callout.copyWith(color: c.mute)),
                      ),
                      CwGroup(
                        children: [
                          _source(
                              CwIcons.wallet,
                              const Color(0xFF1F3A93),
                              'cwSrcStocard',
                              'cwSrcStocardSub',
                              () => _pick(stocardGuide: true)),
                          _source(CwIcons.stack, const Color(0xFF0E7C66),
                              'cwSrcCatima', 'cwSrcCatimaSub', _pick),
                          _source(CwIcons.gift, const Color(0xFFD6336C),
                              'cwSrcFidme', 'cwSrcFidmeSub', _pick),
                          _source(CwIcons.walletPass, c.ink, 'cwSrcPkpass',
                              'cwSrcPkpassSub', _pick),
                          _source(CwIcons.document, c.ink2, 'cwSrcCsv',
                              'cwSrcCsvSub', _pick),
                          _source(CwIcons.photos, c.ink2, 'cwSrcPhotos',
                              'cwSrcPhotosSub', _pickPhotos,
                              key: const ValueKey('importPhotos')),
                        ],
                      ),
                      if (_reading != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'cwReadingPhotos'.tr(args: [
                                  '${_reading!.$1}',
                                  '${_reading!.$2}'
                                ]),
                                style: CwType.callout.copyWith(color: c.ink2),
                              ),
                            ],
                          ),
                        ),
                      if (r != null) ...[
                        CwSectionHeader('cwFoundInFile'.tr(), key: _foundKey),
                        CwGroup(
                          children: [
                            for (var i = 0; i < r.cards.length; i++)
                              _FoundRow(
                                key: ValueKey('found_$i'),
                                card: r.cards[i],
                                on: _on.contains(i),
                                onChanged: (v) => setState(
                                    () => v ? _on.add(i) : _on.remove(i)),
                                onRename: () => _rename(i),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      CwTrustLine('cwEncryptedLocal'.tr()),
                    ],
                  ),
                ),
              ),
              if (r != null && _overFreeLimit())
                Padding(
                  key: const ValueKey('importOverLimit'),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                  child: Text(
                    'cwImportOverLimit'
                        .tr(args: ['${PremiumService.maxLoyaltyCardsForFree}']),
                    textAlign: TextAlign.center,
                    style: CwType.footnote.copyWith(color: c.mute),
                  ),
                ),
              if (r != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                  child: CwButton(
                    'cwImportN'.plural(_on.length),
                    loading: _busy,
                    onPressed: _on.isEmpty || _busy ? null : _import,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _source(CwIcons icon, Color color, String title, String sub,
          VoidCallback onTap,
          {Key? key}) =>
      CwRow(
        key: key,
        leading: CwIconTile(icon, color: color),
        title: title.tr(),
        subtitle: sub.tr(),
        chevron: true,
        onTap: onTap,
      );
}

class _FoundRow extends StatelessWidget {
  final ImportedCard card;
  final bool on;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onRename;

  const _FoundRow({
    super.key,
    required this.card,
    required this.on,
    required this.onChanged,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final colour = card.color != null
        ? Color(card.color!)
        : BrandCatalog.instance.match(card.name) != null
            ? Color(BrandCatalog.instance.match(card.name)!.color)
            : c.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Row(
        children: [
          if (card.photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.memory(card.photo!,
                  width: 32, height: 32, fit: BoxFit.cover, cacheWidth: 96),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: card.barcodeValid ? colour : c.warn,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: card.barcodeValid
                  ? Text(
                      card.name.characters.take(1).toString().toUpperCase(),
                      style: CwType.callout.copyWith(
                          color: colour.computeLuminance() > 0.55
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.w800),
                    )
                  : const CwIcon(CwIcons.warning,
                      size: 16, color: Colors.white),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRename,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(card.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CwType.callout.copyWith(
                                color: c.ink, fontWeight: FontWeight.w600)),
                      ),
                      if (onRename != null) ...[
                        const SizedBox(width: 6),
                        CwIcon(CwIcons.edit, size: 14, color: c.mute),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  card.barcodeValid
                      ? Text(card.barcode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CwType.mono(size: 12, color: c.mute))
                      : card.photoOnly
                          ? Text('cwImportPhotoOnly'.tr(),
                              style: CwType.caption.copyWith(color: c.mute))
                          : Text('cwImportInvalid'.tr(),
                              style: CwType.caption.copyWith(color: c.warn)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CwSwitch(value: on, onChanged: onChanged),
        ],
      ),
    );
  }
}
