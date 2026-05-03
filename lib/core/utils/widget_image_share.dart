import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallet_app/core/utils/share_origin.dart';

/// Renders [widget] into a PNG and hands it off to the system share sheet.
///
/// The widget is mounted into the active [Overlay] at a far off-screen
/// position so it can be laid out and painted without flashing on top of
/// the UI. After one frame the [RepaintBoundary] is captured and the
/// overlay entry is torn down.
///
/// [size] must be set explicitly — the widget is rendered with a fixed
/// canvas, no MediaQuery or parent constraints to inherit. Pixel ratio
/// defaults to 3.0 so the resulting PNG looks crisp on high-DPI sharing
/// targets (Twitter/X compresses to ~2x).
///
/// Returns true if the share sheet was presented; false on capture or IO
/// failure (callers can show a snackbar in that case).
Future<bool> shareWidgetAsImage({
  required BuildContext context,
  required Widget widget,
  required Size size,
  String filename = 'card.png',
  String? text,
  String? subject,
  double pixelRatio = 3.0,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundaryKey = GlobalKey();
  // Capture before any awaits so we still have a valid render box even if
  // the caller's widget unmounts while we're rendering off-screen.
  final shareOrigin = shareOriginFromContext(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) {
      // Push the widget far off-screen. Negative offsets large enough that
      // even worst-case pivots (rotated content) can't bleed back into the
      // visible area.
      return Positioned(
        left: -size.width - 4000,
        top: -size.height - 4000,
        width: size.width,
        height: size.height,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: widget,
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  try {
    // Wait for layout + paint. One end-of-frame is enough for static
    // content; the delay covers async children (cached-network images
    // resolving from disk, QR/barcode generation) that schedule a second
    // frame. Anything network-bound should be precached by the caller
    // before reaching this helper — see ShareableLoyaltyCard.precacheBrandLogo.
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 200));
    await WidgetsBinding.instance.endOfFrame;

    final renderObject =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (renderObject == null) return false;

    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return false;
    final bytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
        subject: subject,
        sharePositionOrigin: shareOrigin,
      ),
    );
    return true;
  } catch (_) {
    return false;
  } finally {
    entry.remove();
  }
}
