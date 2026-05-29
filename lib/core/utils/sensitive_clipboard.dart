import 'package:flutter/services.dart';

/// Copies sensitive values (card numbers, IBANs, barcodes) to the clipboard
/// and auto-clears them after [_clearAfter] unless the user copies something
/// else via [copy] in the meantime.
///
/// The plain `Clipboard.setData` API persists indefinitely; this wrapper
/// gives card data the same "burn-after-paste" lifetime that password
/// managers use, so we don't leave a card number sitting in the system
/// clipboard for arbitrary later apps to read.
///
/// We deliberately do not call `Clipboard.getData` before wiping (which
/// would let us tell whether the user copied something else from outside
/// our app) — on iOS 14+ that call triggers a system "X pasted from your
/// clipboard" toast that would fire every 60s. The epoch counter makes the
/// timer a no-op when our copy has already been superseded by another
/// sensitive copy.
class SensitiveClipboard {
  const SensitiveClipboard._();

  static const Duration _clearAfter = Duration(seconds: 60);
  static int _epoch = 0;

  static Future<void> copy(String value) async {
    final myEpoch = ++_epoch;
    await Clipboard.setData(ClipboardData(text: value));

    Future.delayed(_clearAfter, () async {
      if (myEpoch != _epoch) return;
      await Clipboard.setData(const ClipboardData(text: ''));
    });
  }
}
