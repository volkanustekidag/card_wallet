import 'package:flutter/material.dart';

/// iOS' UIActivityViewController must be anchored to a non-zero rect inside
/// the source view's coordinate space. Without it `share_plus` throws
/// `sharePositionOrigin: argument must be set` on iPad and on iPhone running
/// recent iOS versions. We derive the rect from the calling widget so the
/// share sheet popover lines up with whatever the user tapped.
Rect shareOriginFromContext(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    final origin = box.localToGlobal(Offset.zero);
    final rect = origin & box.size;
    if (!rect.isEmpty) return rect;
  }
  final size = MediaQuery.maybeOf(context)?.size ?? const Size(1, 1);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 1,
    height: 1,
  );
}
