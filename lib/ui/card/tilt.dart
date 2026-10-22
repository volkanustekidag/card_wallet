import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Shared, low-pass-filtered device tilt in the range [-1, 1] on both axes.
///
/// The accelerometer is only listened to while at least one widget is
/// subscribed (the focused card), so idle screens cost nothing. Used to
/// slide the specular highlight across card faces.
class CwTilt {
  CwTilt._();
  static final CwTilt instance = CwTilt._();

  final ValueNotifier<Offset> value = ValueNotifier(Offset.zero);
  StreamSubscription<AccelerometerEvent>? _sub;
  int _listeners = 0;
  Offset _smoothed = Offset.zero;

  void attach() {
    _listeners++;
    if (_sub != null) return;
    try {
      _sub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(_onEvent, onError: (_) {}, cancelOnError: false);
    } catch (_) {
      // No sensor (simulator, desktop) — the shine just stays centred.
    }
  }

  void detach() {
    _listeners = (_listeners - 1).clamp(0, 1 << 20);
    if (_listeners == 0) {
      _sub?.cancel();
      _sub = null;
      _smoothed = Offset.zero;
      value.value = Offset.zero;
    }
  }

  void _onEvent(AccelerometerEvent e) {
    // Gravity components: x left/right roll, y forward/back pitch.
    final target = Offset(
      (e.x / 6).clamp(-1.0, 1.0),
      ((e.y - 6) / 6).clamp(-1.0, 1.0),
    );
    _smoothed = Offset.lerp(_smoothed, target, 0.12)!;
    // Skip sub-pixel noise to avoid needless repaints.
    if ((_smoothed - value.value).distance > 0.01) {
      value.value = _smoothed;
    }
  }
}

/// Mixin for widgets that want live tilt while mounted.
mixin CwTiltSubscriber<T extends StatefulWidget> on State<T> {
  bool get wantsTilt;
  bool _attached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final want = wantsTilt && !reduce;
    if (want && !_attached) {
      CwTilt.instance.attach();
      _attached = true;
    } else if (!want && _attached) {
      CwTilt.instance.detach();
      _attached = false;
    }
  }

  @override
  void dispose() {
    if (_attached) CwTilt.instance.detach();
    super.dispose();
  }
}
