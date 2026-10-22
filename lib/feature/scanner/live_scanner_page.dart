import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_barcode_scanner_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/utils/scan_photo_cleanup.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/scanner/add_flows.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// One camera for everything: bank cards (OCR), loyalty barcodes and IBANs
/// (printed or as a SEPA QR). Frames are analysed on-device and never
/// stored. Barcodes are accepted on the first read; OCR needs the same
/// result in two frames so a half-read number never lands in a form.
class LiveScannerPage extends StatefulWidget {
  final ScanMode initialMode;

  /// Pop with the [ScanHit] instead of routing it (a form's "Scan" button).
  final bool returnHit;

  const LiveScannerPage({
    super.key,
    this.initialMode = ScanMode.auto,
    this.returnHit = false,
  });

  @override
  State<LiveScannerPage> createState() => _LiveScannerPageState();
}

enum _CamState { starting, live, denied, unavailable }

class _LiveScannerPageState extends State<LiveScannerPage>
    with WidgetsBindingObserver {
  late ScanMode _mode = widget.initialMode;
  CameraController? _camera;
  _CamState _state = _CamState.starting;
  bool _torch = false;

  final BarcodeScanner _barcodes = BarcodeScanner();
  final TextRecognizer _text = TextRecognizer();
  bool _busy = false;
  bool _handling = false;
  int _frame = 0;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  ScanHit? _pending;
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.instance.logScanStarted(
        type: 'any', method: AnalyticsScanMethod.camera);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _barcodes.close();
    _text.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only a real background trip releases the camera; permission dialogs
    // and the notification shade just make the app inactive.
    if (state == AppLifecycleState.paused) {
      _stop();
    } else if (state == AppLifecycleState.resumed &&
        _camera == null &&
        !_starting &&
        _state != _CamState.denied &&
        !_handling) {
      _start();
    }
  }

  bool _starting = false;

  Future<void> _start() async {
    if (_starting || _camera != null) return;
    _starting = true;
    try {
      await _startCamera();
    } finally {
      _starting = false;
    }
  }

  Future<void> _startCamera() async {
    final status = await AppLockService.guard(() => Permission.camera.request());
    if (!mounted) return;
    if (!status.isGranted && !status.isLimited) {
      setState(() => _state = _CamState.denied);
      return;
    }
    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (_) {
      cameras = const [];
    }
    if (cameras.isEmpty) {
      if (mounted) setState(() => _state = _CamState.unavailable);
      return;
    }
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    // 720p reads card numbers well; fall back for devices that can't
    // stream that alongside the preview.
    for (final preset in const [ResolutionPreset.high, ResolutionPreset.medium]) {
      final controller = CameraController(
        back,
        preset,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      try {
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        await controller.startImageStream(_onFrame);
        _camera = controller;
        setState(() => _state = _CamState.live);
        return;
      } catch (e) {
        debugPrint('Scanner camera error ($preset): $e');
        await controller.dispose();
      }
    }
    if (mounted) setState(() => _state = _CamState.unavailable);
  }

  Future<void> _stop() async {
    final c = _camera;
    _camera = null;
    _torch = false;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    await c.dispose();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _handling) return;
    final now = DateTime.now();
    if (now.difference(_lastRun) < const Duration(milliseconds: 220)) return;
    _lastRun = now;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      _frame++;
      ScanHit? hit;
      if (_mode != ScanMode.card) {
        final found = await _barcodes.processImage(input);
        for (final b in found) {
          hit = ScanAnalyzer.fromBarcode(b.rawValue ?? '',
              LoyaltyBarcodeScannerService.mapFormat(b.format), _mode);
          if (hit != null) break;
        }
        // Barcodes decode exactly: accept right away, naming the brand
        // when the card's printed text matches the catalogue.
        if (hit is LoyaltyHit) {
          final text = await _text.processImage(input);
          return _accept(hit.withBrand(brandFromText(text.text)));
        }
        if (hit != null) return _accept(hit);
      }
      // OCR is costlier; in auto mode run it every other frame.
      if (_mode == ScanMode.barcode) return;
      if (_mode == ScanMode.auto && _frame.isOdd) return;
      final text = await _text.processImage(input);
      hit = ScanAnalyzer.fromText(text.text, _mode);
      if (hit == null) {
        _pending = null;
        return;
      }
      final previous = _pending;
      if (previous != null && previous.sameAs(hit)) {
        return _accept(_merge(previous, hit));
      }
      _pending = hit;
      if (mounted) setState(() => _status = _holdLabel(hit!));
    } catch (e) {
      debugPrint('Scanner frame error: $e');
    } finally {
      _busy = false;
    }
  }

  /// Keeps expiry / name from whichever frame read them.
  ScanHit _merge(ScanHit a, ScanHit b) {
    if (a is CardHit && b is CardHit) {
      return CardHit(b.number,
          expiry: b.expiry ?? a.expiry, holder: b.holder ?? a.holder);
    }
    return b;
  }

  String _holdLabel(ScanHit hit) {
    if (hit is CardHit) {
      final n = CardBankDetector.networkFor(hit.number);
      final name = n == CardNetwork.unknown ? 'cwModeCard'.tr() : n.label;
      return 'cwScanHold'.tr(args: [name]);
    }
    return 'cwScanHold'.tr(args: ['IBAN']);
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera;
    if (camera == null) return null;
    final rotation = InputImageRotationValue.fromRawValue(
            camera.description.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        // The app is portrait-locked, so the sensor orientation is the
        // rotation on both platforms (ML Kit camera example).
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _accept(ScanHit hit) async {
    if (_handling) return;
    _handling = true;
    _pending = null;
    HapticFeedback.mediumImpact();
    AnalyticsService.instance.logScanSucceeded(
        type: _typeOf(hit), method: AnalyticsScanMethod.camera);
    if (mounted) {
      setState(() => _status = switch (hit) {
            LoyaltyHit() => 'cwScanFoundBarcode'.tr(),
            IbanHit() => 'cwScanFoundIban'.tr(),
            CardHit() => 'cwScanFoundCard'.tr(),
          });
    }
    try {
      await _camera?.stopImageStream();
    } catch (_) {}
    if (!mounted) return;
    if (widget.returnHit) {
      Navigator.of(context).pop(hit);
      return;
    }
    final done = await handleScanHit(context, hit);
    if (!mounted) return;
    if (done) return;
    // Dismissed: keep scanning.
    _handling = false;
    setState(() => _status = null);
    try {
      if (_camera != null && !_camera!.value.isStreamingImages) {
        await _camera!.startImageStream(_onFrame);
      }
    } catch (_) {}
  }

  static String _typeOf(ScanHit hit) => switch (hit) {
        LoyaltyHit() => AnalyticsCardType.loyalty,
        IbanHit() => AnalyticsCardType.iban,
        CardHit() => AnalyticsCardType.credit,
      };

  Future<void> _fromPhotos() async {
    if (_handling) return;
    _handling = true;
    XFile? photo;
    try {
      photo = await AppLockService.guard(() => ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 100));
      if (photo == null || !mounted) return;
      final input = InputImage.fromFilePath(photo.path);
      ScanHit? hit;
      if (_mode != ScanMode.card) {
        for (final b in await _barcodes.processImage(input)) {
          hit = ScanAnalyzer.fromBarcode(b.rawValue ?? '',
              LoyaltyBarcodeScannerService.mapFormat(b.format), _mode);
          if (hit != null) break;
        }
      }
      final text = (await _text.processImage(input)).text;
      if (hit is LoyaltyHit) hit = hit.withBrand(brandFromText(text));
      if (hit == null && _mode != ScanMode.barcode) {
        hit = ScanAnalyzer.fromText(text, _mode);
      }
      if (!mounted) return;
      if (hit == null) {
        AnalyticsService.instance.logScanFailed(
            type: 'any', method: AnalyticsScanMethod.gallery);
        context.showInfoSnackBar('cwNothingInPhoto');
        return;
      }
      AnalyticsService.instance.logScanSucceeded(
          type: _typeOf(hit), method: AnalyticsScanMethod.gallery);
      if (widget.returnHit) {
        Navigator.of(context).pop(hit);
        return;
      }
      _handling = false;
      await _stop();
      if (!mounted) return;
      _handling = true;
      final done = await handleScanHit(context, hit);
      if (!done && mounted) {
        _handling = false;
        _start();
      }
    } catch (e) {
      debugPrint('Photo scan error: $e');
      if (mounted) context.showInfoSnackBar('cwNothingInPhoto');
    } finally {
      await deleteScanPhoto(photo, fromCamera: false);
      if (mounted && _camera != null) _handling = false;
    }
  }

  Future<void> _toggleTorch() async {
    final c = _camera;
    if (c == null) return;
    try {
      await c.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      setState(() => _torch = !_torch);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    final size = MediaQuery.sizeOf(context);
    final frameW = size.width - 36;
    final frameH = _mode == ScanMode.barcode ? frameW * 0.62 : frameW / 1.586;
    final live = _state == _CamState.live && _camera != null;
    final detecting = _status != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0C0F),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (live)
              _CoverPreview(controller: _camera!)
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.1,
                    colors: [Color(0xFF2A2B30), Color(0xFF0B0C0F)],
                  ),
                ),
              ),
            // Dim everything outside the frame.
            if (live || _state == _CamState.starting)
              IgnorePointer(
              child: CustomPaint(
                painter: _FramePainter(
                  frame: Size(frameW, frameH),
                  centerY: size.height * 0.44,
                  active: detecting,
                  dim: live ? 0.62 : 0,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    child: Row(
                      children: [
                        _RoundIcon(
                          icon: CwIcons.close,
                          label: 'cwClose'.tr(),
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        if (live)
                          _RoundIcon(
                            icon: CwIcons.flash,
                            label: 'cwTorch'.tr(),
                            selected: _torch,
                            onTap: _toggleTorch,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('cwScanTitle'.tr(),
                      style: CwType.title.copyWith(color: night.ink)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'cwScanSub'.tr(),
                      textAlign: TextAlign.center,
                      style: CwType.footnote.copyWith(color: night.ink2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: CwSegmented<ScanMode>(
                      onDark: true,
                      values: ScanMode.values,
                      selected: _mode,
                      label: (m) => switch (m) {
                        ScanMode.auto => 'cwModeAuto'.tr(),
                        ScanMode.card => 'cwModeCard'.tr(),
                        ScanMode.barcode => 'cwModeBarcode'.tr(),
                        ScanMode.iban => 'cwModeIban'.tr(),
                      },
                      onChanged: (m) => setState(() {
                        _mode = m;
                        _pending = null;
                        _status = null;
                      }),
                    ),
                  ),
                  const Spacer(),
                  if (!live && _state != _CamState.starting)
                    _CameraOff(
                      denied: _state == _CamState.denied,
                    ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: CwMotion.fast,
                    child: _StatusPill(
                      key: ValueKey(_status ?? 'idle'),
                      text: _status ??
                          (live ? 'cwScanLooking'.tr() : null),
                      active: detecting,
                    ),
                  ),
                  SizedBox(height: size.height * 0.06),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: widget.returnHit
                        ? _BottomAction(
                            icon: CwIcons.photos,
                            label: 'cwFromPhotos'.tr(),
                            onTap: _fromPhotos,
                          )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomAction(
                          icon: CwIcons.photos,
                          label: 'cwFromPhotos'.tr(),
                          onTap: _fromPhotos,
                        ),
                        _BottomAction(
                          icon: CwIcons.import,
                          label: 'cwImport'.tr(),
                          onTap: () => openImport(context, replace: true),
                        ),
                        _BottomAction(
                          icon: CwIcons.keyboard,
                          label: 'cwTypeIt'.tr(),
                          onTap: () => pickManualEntry(context, replace: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A catalogue brand named on its own line of the card's text.
BrandEntry? brandFromText(String text) {
  final catalog = BrandCatalog.instance;
  for (final line in text.split('\n')) {
    if (line.trim().length < 3) continue;
    final hit = catalog.match(line);
    if (hit != null) return hit;
  }
  return null;
}

/// Camera preview scaled to cover the screen (no letterboxing).
class _CoverPreview extends StatelessWidget {
  final CameraController controller;
  const _CoverPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final ratio = controller.value.aspectRatio; // landscape w/h
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 1000,
          height: 1000 * ratio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Size frame;
  final double centerY;
  final bool active;
  final double dim;

  _FramePainter({
    required this.frame,
    required this.centerY,
    required this.active,
    required this.dim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, centerY),
      width: frame.width,
      height: frame.height,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    if (dim > 0) {
      final outside = Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rrect),
      );
      canvas.drawPath(
          outside, Paint()..color = Colors.black.withValues(alpha: dim));
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 3 : 2
        ..color = active
            ? const Color(0xFF34D399)
            : Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.frame != frame ||
      old.centerY != centerY ||
      old.active != active ||
      old.dim != dim;
}

class _StatusPill extends StatelessWidget {
  final String? text;
  final bool active;
  const _StatusPill({super.key, required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox(height: 34);
    final fg = active ? const Color(0xFF34D399) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF34D399).withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text!,
        style: CwType.footnote.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final CwIcons icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: CwIcon(icon,
                    size: 20,
                    color: selected ? const Color(0xFF0B0C0F) : Colors.white),
              ),
            ),
          ),
        ),
      );
}

class _BottomAction extends StatelessWidget {
  final CwIcons icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: CwIcon(icon, size: 22, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: CwType.caption.copyWith(color: Colors.white)),
            ],
          ),
        ),
      );
}

class _CameraOff extends StatelessWidget {
  final bool denied;
  const _CameraOff({required this.denied});

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const CwIcon(CwIcons.camera, size: 30, color: Colors.white),
          const SizedBox(height: 10),
          Text('cwCameraOff'.tr(),
              textAlign: TextAlign.center,
              style: CwType.headline.copyWith(color: night.ink)),
          const SizedBox(height: 4),
          Text('cwCameraOffSub'.tr(),
              textAlign: TextAlign.center,
              style: CwType.footnote.copyWith(color: night.ink2)),
          if (denied) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => AppLockService.guard(() => openAppSettings()),
              child: Text('openSettings'.tr(),
                  style: CwType.callout.copyWith(
                      color: night.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
