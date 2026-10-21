import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Reports handled-but-unexpected errors (the ones a `catch` swallows so the
/// UI keeps working) as non-fatal Crashlytics events in release builds.
/// Debug builds only print.
///
/// Never pass card numbers, IBANs, barcodes or names in [reason]; the
/// error object itself should describe the failure, not the data.
class ErrorReporter {
  const ErrorReporter._();

  static void report(Object error, StackTrace? stack, {String? reason}) {
    if (kDebugMode) {
      debugPrint('[$reason] $error');
      return;
    }
    if (Firebase.apps.isEmpty) return;
    FirebaseCrashlytics.instance
        .recordError(error, stack, reason: reason, fatal: false)
        .ignore();
  }
}
