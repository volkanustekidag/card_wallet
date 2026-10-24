import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/data/storage/card_photo_store.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/barcode_display_boost.dart';
import 'package:wallet_app/core/services/widget_data_service.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_formats.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_validator.dart';
import 'package:wallet_app/feature/loyalty_card/utils/loyalty_wallet_action.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/card_photos.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/shareable_loyalty_card.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/navigation/card_expand_route.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Checkout: the loyalty card's barcode, ready for the till.
///
/// Brand-coloured stage, a white barcode panel (format, validity, use
/// count), automatic max brightness, and a giant landscape barcode when the
/// phone is turned sideways (the app itself stays portrait-locked).
class LoyaltyCardDetailPage extends StatefulWidget {
  final LoyaltyCard card;

  /// Opened from the home/lock-screen widget while the app is PIN-locked.
  /// Only the barcode and the card name are shown; edit, delete, copy,
  /// share, wallet export and notes stay behind the PIN.
  final bool readOnly;

  const LoyaltyCardDetailPage({
    Key? key,
    required this.card,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<LoyaltyCardDetailPage> createState() => _LoyaltyCardDetailPageState();
}

class _LoyaltyCardDetailPageState extends State<LoyaltyCardDetailPage> {
  /// Re-read after an edit: saving stores a new object under the card's id.
  late LoyaltyCard _card = widget.card;
  LoyaltyCard get card => _card;
  bool get readOnly => widget.readOnly;

  StreamSubscription<AccelerometerEvent>? _accel;
  bool _landscapeOpen = false;
  DateTime? _sidewaysSince;

  @override
  void initState() {
    super.initState();
    // Opening the barcode IS the "use" event — that's when the cashier
    // sees the code. Fire-and-forget; nothing here may block rendering.
    WidgetDataService.instance.setLastUsedLoyaltyCard(card);
    BarcodeDisplayBoost.instance.acquire();
    AnalyticsService.instance
        .logBarcodeShown(readOnly ? 'widget' : 'detail_page');
    LoyaltyCardService().recordUseInBackground(card.id);
    try {
      _accel = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(_onAccel, onError: (_) {}, cancelOnError: false);
    } catch (_) {
      // No sensor: the barcode can still be enlarged by tapping it.
    }
  }

  @override
  void dispose() {
    _accel?.cancel();
    BarcodeDisplayBoost.instance.release();
    super.dispose();
  }

  void _onAccel(AccelerometerEvent e) {
    if (_landscapeOpen || !mounted || !card.hasBarcode) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final sideways = e.x.abs() > 7.0 && e.y.abs() < 4.5;
    if (!sideways) {
      _sidewaysSince = null;
      return;
    }
    final since = _sidewaysSince ??= DateTime.now();
    if (DateTime.now().difference(since) > const Duration(milliseconds: 250)) {
      _sidewaysSince = null;
      _openLandscape(turnLeft: e.x > 0);
    }
  }

  Future<void> _openLandscape({bool turnLeft = true}) async {
    if (_landscapeOpen) return;
    _landscapeOpen = true;
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: CwMotion.base,
      reverseTransitionDuration: CwMotion.fast,
      pageBuilder: (_, __, ___) =>
          _LandscapeBarcode(card: card, quarterTurns: turnLeft ? 1 : 3),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
    _landscapeOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final item = WalletItem.loyalty(card);
    final m = materialForItem(item);
    final fg = m.foreground;
    final check =
        LoyaltyBarcodeValidator.validate(card.barcode, card.barcodeFormat);
    final brand =
        (card.brand?.trim().isNotEmpty ?? false) ? card.brand!.trim() : '';
    final hasNotes = !readOnly && (card.notes?.trim().isNotEmpty ?? false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: fg == Colors.white
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: m.colors.last,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(decoration: checkoutBackground(m)),
            ),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    fg: fg,
                    readOnly: readOnly,
                    onClose: () => Navigator.of(context).maybePop(),
                    onMore: _openMore,
                  ),
                  Expanded(
                    child: CheckoutRiseIn(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                            18, 10, 18, readOnly ? 24 : 120),
                        children: [
                          Center(child: CardLogoChip(item: item, size: 64)),
                          const SizedBox(height: 12),
                          Text(
                            titleForItem(item),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                CwType.title.copyWith(color: fg, fontSize: 24),
                          ),
                          if (brand.isNotEmpty && brand != card.name.trim())
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                brand,
                                textAlign: TextAlign.center,
                                style: CwType.footnote
                                    .copyWith(color: fg.withValues(alpha: 0.7)),
                              ),
                            ),
                          const SizedBox(height: 24),
                          if (card.hasBarcode) ...[
                            _BarcodePanel(
                              card: card,
                              valid: check.isValid,
                              onTap: () => _openLandscape(),
                              onFix: readOnly ? null : _onEdit,
                            ),
                            const SizedBox(height: 16),
                            _Hint(
                              fg: fg,
                              icon: CwIcons.rotate,
                              text: 'cwTurnSideways'.tr(),
                            ),
                            if (card.photoIds.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _PhotoStrip(
                                card: card,
                                fg: fg,
                                onOpen: (i) =>
                                    showCardPhotos(context, card, initial: i),
                              ),
                            ],
                          ] else ...[
                            _PhotoPanel(
                              card: card,
                              onOpen: (i) =>
                                  showCardPhotos(context, card, initial: i),
                            ),
                            const SizedBox(height: 16),
                            _Hint(
                              fg: fg,
                              icon: CwIcons.photos,
                              text: 'cwShowPhotoAtCheckout'.tr(),
                            ),
                          ],
                          if (hasNotes) ...[
                            const SizedBox(height: 18),
                            _GlassBox(
                              fg: fg,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('cwNotes'.tr().toUpperCase(),
                                      style: CwType.overline.copyWith(
                                          color: fg.withValues(alpha: 0.7))),
                                  const SizedBox(height: 6),
                                  SelectableText(card.notes!.trim(),
                                      style:
                                          CwType.callout.copyWith(color: fg)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18 + MediaQuery.paddingOf(context).bottom,
              child: readOnly
                  ? _Dock(fg: fg, actions: [
                      _DockAction(CwIcons.unlock, 'openApp'.tr(), _onOpenApp),
                    ])
                  : _Dock(fg: fg, actions: [
                      if (card.hasBarcode)
                        _DockAction(CwIcons.copy, 'cwCopy'.tr(), _onCopy),
                      _DockAction(CwIcons.share, 'cwShare'.tr(),
                          () => _onShare(context)),
                      if (card.hasBarcode)
                        _DockAction(
                          CwIcons.walletPass,
                          'cwDockWallet'.tr(),
                          () => addLoyaltyCardToWallet(context, card),
                          semantic: loyaltyWalletActionLabel(context),
                        ),
                      _DockAction(CwIcons.edit, 'cwEdit'.tr(), _onEdit),
                    ]),
            ),
          ],
        ),
      ),
    );
  }

  void _onCopy() {
    SensitiveClipboard.copy(
      card.barcode,
      cardType: AnalyticsCardType.loyalty,
    );
    HapticFeedback.lightImpact();
    Get.context?.showSuccessSnackBar('cwBarcodeCopied');
  }

  Future<void> _openMore() async {
    final c = CwColors.of(context);
    final fav = isFavoriteCard(card);
    await showCwSheet<void>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: CwGroup(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            CwRow(
              leading: CwIcon(fav ? CwIcons.starFill : CwIcons.star,
                  color: fav ? c.warn : c.ink),
              title: fav ? 'cwFavRemove'.tr() : 'cwFavAdd'.tr(),
              onTap: () {
                Navigator.pop(sheet);
                HapticFeedback.lightImpact();
                toggleFavoriteTag(card);
                if (mounted) setState(() {});
              },
            ),
            CwRow(
              leading: CwIcon(CwIcons.edit, color: c.ink),
              title: 'cwEdit'.tr(),
              onTap: () {
                Navigator.pop(sheet);
                _onEdit();
              },
            ),
            CwRow(
              leading: CwIcon(CwIcons.trash, color: c.danger),
              title: 'cwDelete'.tr(),
              titleColor: c.danger,
              onTap: () {
                Navigator.pop(sheet);
                _onDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    AnalyticsService.instance
        .logCardShared(cardType: AnalyticsCardType.loyalty, masked: false);
    if (!card.hasBarcode) {
      // A photo card is shared as its photo.
      final bytes = await CardPhotoStore.instance.load(card.frontPhoto);
      if (bytes == null) return;
      await shareImageBytes(bytes, filename: 'loyalty-${card.id}.jpg');
      return;
    }
    final brandLogo =
        await ShareableLoyaltyCard.precacheBrandLogo(context, card);
    if (!context.mounted) return;
    await shareWidgetAsImage(
      context: context,
      widget: ShareableLoyaltyCard(
        card: card,
        brandLogoImage: brandLogo,
      ),
      size: const Size(
        ShareableLoyaltyCard.width,
        ShareableLoyaltyCard.height,
      ),
      filename: 'loyalty-${card.id}.png',
    );
  }

  /// The PIN screen (cold launch) or the re-lock screen (warm) sits right
  /// below this page, so popping is the way into the app.
  Future<void> _onOpenApp() async {
    final popped = await Navigator.of(context).maybePop();
    if (!popped) Get.offAllNamed(AppRoutes.auth);
  }

  /// Edits on top of this page and comes back to it, updated.
  Future<void> _onEdit() async {
    await Get.to<void>(
      () => AddLoyaltyCardPage(card: card),
      binding: AddLoyaltyCardBindings(),
    );
    final cards = await LoyaltyCardService().getAllLoyaltyCards();
    final fresh = cards.where((c) => c.id == card.id).firstOrNull;
    if (fresh != null && mounted) setState(() => _card = fresh);
  }

  Future<void> _onDelete(BuildContext context) async {
    final ok = await showConfirmActionSheet(
      context: context,
      title: 'deleteCard'.tr(),
      content: 'deleteDataMessage'.tr(),
    );
    if (!ok) return;
    // The list controller is registered lazily app-wide; the service is
    // the fallback if bindings ever change.
    if (Get.isRegistered<LoyaltyCardController>()) {
      await Get.find<LoyaltyCardController>().removeLoyaltyCard(card);
    } else {
      await LoyaltyCardService().removeLoyaltyCard(card);
    }
    if (mounted) Navigator.of(this.context).pop();
  }
}

String formatBarcodeText(String raw) {
  if (raw.length <= 4 || raw.contains(' ')) return raw;
  final b = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && i % 4 == 0) b.write(' ');
    b.write(raw[i]);
  }
  return b.toString();
}

class _TopBar extends StatelessWidget {
  final Color fg;
  final bool readOnly;
  final VoidCallback onClose;
  final VoidCallback onMore;

  const _TopBar({
    required this.fg,
    required this.readOnly,
    required this.onClose,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final glass = fg.withValues(alpha: 0.14);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          _GlassCircle(
            icon: CwIcons.close,
            fg: fg,
            bg: glass,
            label: 'cwClose'.tr(),
            onTap: onClose,
          ),
          const Spacer(),
          Obx(() {
            final on = BarcodeDisplayBoost.instance.enabled.value;
            return Semantics(
              button: true,
              toggled: on,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  BarcodeDisplayBoost.instance.setEnabled(!on);
                },
                child: AnimatedContainer(
                  duration: CwMotion.fast,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: on ? fg.withValues(alpha: 0.22) : glass,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CwIcon(CwIcons.sun,
                          size: 16, color: fg.withValues(alpha: on ? 1 : 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        on ? 'cwMaxBrightness'.tr() : 'cwBrightnessOff'.tr(),
                        style: CwType.caption.copyWith(
                            color: fg.withValues(alpha: on ? 1 : 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (readOnly)
            const SizedBox(width: 40)
          else
            _GlassCircle(
              icon: CwIcons.more,
              fg: fg,
              bg: glass,
              label: 'cwMore'.tr(),
              onTap: onMore,
            ),
        ],
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  final CwIcons icon;
  final Color fg;
  final Color bg;
  final String label;
  final VoidCallback onTap;

  const _GlassCircle({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: CwIcon(icon, size: 20, color: fg)),
            ),
          ),
        ),
      );
}

class _BarcodePanel extends StatelessWidget {
  final LoyaltyCard card;
  final bool valid;
  final VoidCallback onTap;
  final VoidCallback? onFix;

  const _BarcodePanel({
    required this.card,
    required this.valid,
    required this.onTap,
    this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111215);
    const mute = Color(0xFF7C7F88);
    final isQr = isSquareBarcodeFormat(card.barcodeFormat);
    final uses = card.useCount ?? 0;
    return GestureDetector(
      onTap: valid ? onTap : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 60,
              offset: Offset(0, 30),
            ),
          ],
        ),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, box) => BarcodeRenderer(
                data: card.barcode,
                format: card.barcodeFormat,
                qrSize: box.maxWidth.clamp(0, 230).toDouble(),
                barcodeHeight: 150,
                onChangeFormat: onFix,
              ),
            ),
            const SizedBox(height: 14),
            // Plain text: a selectable one would swallow the tap that
            // enlarges the barcode (Copy in the dock copies it unspaced).
            Text(
              formatBarcodeText(card.barcode),
              textAlign: TextAlign.center,
              style: CwType.mono(
                size: isQr ? 15 : 19,
                color: ink,
                letterSpacing: isQr ? 1 : 2.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // All the room the use count leaves (a Flexible next to a
                // Spacer only got half of it and cut "verified" short).
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          valid
                              ? '${barcodeFormatLabel(card.barcodeFormat)} · ${'cwVerified'.tr()}'
                              : barcodeFormatLabel(card.barcodeFormat),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CwType.caption.copyWith(color: mute),
                        ),
                      ),
                      if (valid) ...[
                        const SizedBox(width: 4),
                        const CwIcon(CwIcons.checkCircle,
                            size: 14, color: Color(0xFF12B76A)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'cwUsedTimes'.plural(uses),
                  style: CwType.caption.copyWith(color: mute),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnails of the card's photos under the barcode.
class _PhotoStrip extends StatelessWidget {
  final LoyaltyCard card;
  final Color fg;
  final ValueChanged<int> onOpen;
  const _PhotoStrip(
      {required this.card, required this.fg, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final ids = card.photoIds;
    final labels = [
      if (card.frontPhoto != null) 'cwPhotoFront'.tr(),
      if (card.backPhoto != null) 'cwPhotoBack'.tr(),
    ];
    return _GlassBox(
      fg: fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('cwCardPhotos'.tr().toUpperCase(),
              style:
                  CwType.overline.copyWith(color: fg.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < ids.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: labels[i],
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('detailPhoto_$i'),
                      onTap: () => onOpen(i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1.586,
                          child: CardPhotoImage(ids[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (ids.length == 1) const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

/// A card without a barcode: its front photo, big, where the barcode
/// would be. Tap for full screen.
class _PhotoPanel extends StatelessWidget {
  final LoyaltyCard card;
  final ValueChanged<int> onOpen;
  const _PhotoPanel({required this.card, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final front = card.frontPhoto;
    return Semantics(
      button: true,
      label: 'cwShowPhotoAtCheckout'.tr(),
      child: GestureDetector(
        key: const ValueKey('detailPhotoPanel'),
        onTap: () => onOpen(0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 60,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.586,
              child: front == null ? const SizedBox() : CardPhotoImage(front),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final Color fg;
  final CwIcons icon;
  final String text;
  const _Hint({required this.fg, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = fg.withValues(alpha: 0.75);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CwIcon(icon, size: 16, color: c),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              textAlign: TextAlign.center,
              style: CwType.footnote.copyWith(color: c)),
        ),
      ],
    );
  }
}

class _GlassBox extends StatelessWidget {
  final Color fg;
  final Widget child;
  const _GlassBox({required this.fg, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(CwRadius.m),
          border: Border.all(color: fg.withValues(alpha: 0.14)),
        ),
        child: child,
      );
}

class _DockAction {
  final CwIcons icon;
  final String label;
  final VoidCallback onTap;
  final String? semantic;
  const _DockAction(this.icon, this.label, this.onTap, {this.semantic});
}

/// Frosted action bar floating over the brand colour.
class _Dock extends StatelessWidget {
  final Color fg;
  final List<_DockAction> actions;
  const _Dock({required this.fg, required this.actions});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: fg.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              for (final a in actions)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: a.semantic ?? a.label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: a.onTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CwIcon(a.icon, size: 22, color: fg),
                          const SizedBox(height: 4),
                          Text(
                            a.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CwType.caption
                                .copyWith(color: fg, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White full-screen barcode drawn rotated, as if the phone were in
/// landscape. Closes on tap or when the phone is turned upright again.
class _LandscapeBarcode extends StatefulWidget {
  final LoyaltyCard card;
  final int quarterTurns;
  const _LandscapeBarcode({required this.card, required this.quarterTurns});

  @override
  State<_LandscapeBarcode> createState() => _LandscapeBarcodeState();
}

class _LandscapeBarcodeState extends State<_LandscapeBarcode> {
  StreamSubscription<AccelerometerEvent>? _sub;
  bool _closing = false;

  /// Turning back upright closes the page only once it has been held
  /// sideways: opened with a tap, the phone is already upright.
  bool _wasSideways = false;

  @override
  void initState() {
    super.initState();
    BarcodeDisplayBoost.instance.acquire();
    try {
      _sub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((e) {
        if (e.x.abs() > 7.0 && e.y.abs() < 4.5) {
          _wasSideways = true;
        } else if (_wasSideways && e.y > 7.5 && e.x.abs() < 4) {
          _close();
        }
      }, onError: (_) {}, cancelOnError: false);
    } catch (_) {}
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    BarcodeDisplayBoost.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final isQr = isSquareBarcodeFormat(card.barcodeFormat);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: SafeArea(
            // Tight constraints so the rotated layout fills the screen.
            child: SizedBox.expand(
              child: RotatedBox(
                quarterTurns: widget.quarterTurns,
                child: LayoutBuilder(builder: (context, box) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CwType.headline
                              .copyWith(color: const Color(0xFF111215)),
                        ),
                        const SizedBox(height: 14),
                        BarcodeRenderer(
                          data: card.barcode,
                          format: card.barcodeFormat,
                          qrSize: (box.maxHeight * 0.62).clamp(120, 420),
                          barcodeHeight: box.maxHeight * 0.5,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          formatBarcodeText(card.barcode),
                          style: CwType.mono(
                            size: isQr ? 16 : 22,
                            color: const Color(0xFF111215),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'cwTapToClose'.tr(),
                          style: CwType.caption
                              .copyWith(color: const Color(0xFF7C7F88)),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
