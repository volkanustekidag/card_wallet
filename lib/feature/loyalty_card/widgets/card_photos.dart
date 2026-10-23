import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wallet_app/core/data/storage/card_photo_store.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/services/barcode_display_boost.dart';
import 'package:wallet_app/core/utils/scan_photo_cleanup.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Longest side of a stored card photo: sharp enough for a cashier to read
/// a number off the screen, small enough for backups.
const double kCardPhotoMaxSide = 1600;

/// Camera or library, then stores the photo encrypted. Returns its id, or
/// null when the user backed out.
Future<String?> pickCardPhoto(BuildContext context) async {
  final source = await showCwSheet<ImageSource>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: CwGroup(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            CwRow(
              key: const ValueKey('photoFromCamera'),
              leading: CwIcon(CwIcons.camera, color: c.ink),
              title: 'cwTakePhoto'.tr(),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            CwRow(
              key: const ValueKey('photoFromLibrary'),
              leading: CwIcon(CwIcons.photos, color: c.ink),
              title: 'cwChoosePhoto'.tr(),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );
  if (source == null) return null;
  XFile? file;
  try {
    file = await AppLockService.guard(() => ImagePicker().pickImage(
          source: source,
          maxWidth: kCardPhotoMaxSide,
          maxHeight: kCardPhotoMaxSide,
          imageQuality: 82,
        ));
    if (file == null) return null;
    return await CardPhotoStore.instance.save(await file.readAsBytes());
  } catch (e) {
    debugPrint('Card photo failed: $e');
    return null;
  } finally {
    await deleteScanPhoto(file, fromCamera: source == ImageSource.camera);
  }
}

/// A stored card photo, decrypted on demand.
class CardPhotoImage extends StatelessWidget {
  final String id;
  final BoxFit fit;
  const CardPhotoImage(this.id, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: CardPhotoStore.instance.load(id),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          return ColoredBox(color: CwColors.of(context).surface2);
        }
        return Image.memory(bytes,
            fit: fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium);
      },
    );
  }
}

/// Front / back photo slots in the card form.
class CardPhotoSlots extends StatelessWidget {
  final String? front;
  final String? back;
  final ValueChanged<String?> onFront;
  final ValueChanged<String?> onBack;

  const CardPhotoSlots({
    super.key,
    required this.front,
    required this.back,
    required this.onFront,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Slot(
            key: const ValueKey('photoSlotFront'),
            label: 'cwPhotoFront'.tr(),
            id: front,
            onChanged: onFront,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Slot(
            key: const ValueKey('photoSlotBack'),
            label: 'cwPhotoBack'.tr(),
            id: back,
            onChanged: onBack,
          ),
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  final String label;
  final String? id;
  final ValueChanged<String?> onChanged;
  const _Slot(
      {super.key, required this.label, this.id, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final radius = BorderRadius.circular(CwRadius.m);
    final photo = id;
    return Semantics(
      button: true,
      label: photo == null ? '${'cwAddPhoto'.tr()}: $label' : label,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Material(
          color: c.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              final picked = await pickCardPhoto(context);
              if (picked != null) onChanged(picked);
            },
            child: photo == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: c.line, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CwIcon(CwIcons.camera,
                            size: CwIconSize.m, color: c.mute),
                        const SizedBox(height: 6),
                        Text(label,
                            style: CwType.footnote.copyWith(
                                color: c.ink2, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CardPhotoImage(photo),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: _Chip(text: label),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Semantics(
                          button: true,
                          label: 'cwRemovePhoto'.tr(),
                          excludeSemantics: true,
                          child: GestureDetector(
                            key: ValueKey('photoRemove_$label'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onChanged(null);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0x99000000),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const CwIcon(CwIcons.close,
                                  size: 14, color: Colors.white),
                            ),
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
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x99000000),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: CwType.caption.copyWith(color: Colors.white, fontSize: 11)),
      );
}

/// Full-screen photos of [card] for the cashier: swipe front / back, pinch
/// to zoom, screen at full brightness.
Future<void> showCardPhotos(BuildContext context, LoyaltyCard card,
    {int initial = 0}) {
  HapticFeedback.selectionClick();
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: true,
    transitionDuration: CwMotion.base,
    reverseTransitionDuration: CwMotion.fast,
    pageBuilder: (_, __, ___) => CardPhotoViewer(card: card, initial: initial),
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
  ));
}

class CardPhotoViewer extends StatefulWidget {
  final LoyaltyCard card;
  final int initial;
  const CardPhotoViewer({super.key, required this.card, this.initial = 0});

  @override
  State<CardPhotoViewer> createState() => _CardPhotoViewerState();
}

class _CardPhotoViewerState extends State<CardPhotoViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void initState() {
    super.initState();
    BarcodeDisplayBoost.instance.acquire();
  }

  @override
  void dispose() {
    _pages.dispose();
    BarcodeDisplayBoost.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.card.photoIds;
    final labels = [
      if (widget.card.frontPhoto != null) 'cwPhotoFront'.tr(),
      if (widget.card.backPhoto != null) 'cwPhotoBack'.tr(),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: ids.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                      child: CardPhotoImage(ids[i], fit: BoxFit.contain)),
                ),
              ),
              Positioned(
                left: 14,
                top: 6,
                child: Semantics(
                  button: true,
                  label: 'cwClose'.tr(),
                  excludeSemantics: true,
                  child: Material(
                    color: const Color(0x33FFFFFF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                            child: CwIcon(CwIcons.close,
                                size: 20, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              if (labels.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => _pages.animateToPage(i,
                                duration: CwMotion.base,
                                curve: CwMotion.standard),
                            child: AnimatedContainer(
                              duration: CwMotion.fast,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? Colors.white
                                    : const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                labels[i],
                                style: CwType.footnote.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      i == _index ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
