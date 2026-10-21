import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/styles/app_themes.dart';
import 'package:wallet_app/feature/boot/boot_error_page.dart';

/// Runs [boot] and returns the error it threw, or null on success.
Future<Object?> runBoot(Future<void> Function() boot) async {
  try {
    await boot();
    return null;
  } catch (e, st) {
    ErrorReporter.report(
      e,
      st,
      reason: e is StorageUnavailableException
          ? 'boot_storage_unavailable'
          : 'boot_failed',
    );
    return e;
  }
}

/// Runs the critical init and then *always* calls [run] — an exception that
/// escapes before runApp leaves the user on the native splash forever.
/// [wrap] adds the app-wide ancestors (EasyLocalization).
Future<void> bootAndRunApp({
  required Future<void> Function() boot,
  required Widget Function(Widget root) wrap,
  required Widget app,
  void Function(Widget app) run = runApp,
}) async {
  final error = await runBoot(boot);
  run(wrap(BootGate(boot: boot, initialError: error, child: app)));
}

/// Shows [child] once boot has succeeded, [BootErrorPage] until then. Retries
/// on demand and whenever the app comes back to the foreground (the usual
/// fix is unlocking the phone).
class BootGate extends StatefulWidget {
  final Future<void> Function() boot;
  final Object? initialError;
  final Widget child;

  const BootGate({
    super.key,
    required this.boot,
    required this.initialError,
    required this.child,
  });

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> with WidgetsBindingObserver {
  Object? _error;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _error != null) {
      unawaited(_retry());
    }
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final error = await runBoot(widget.boot);
    if (!mounted) return;
    setState(() {
      _error = error;
      _retrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) return widget.child;
    final l10n = EasyLocalization.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Card Wallet',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      locale: l10n?.locale,
      localizationsDelegates: l10n?.delegates,
      supportedLocales: l10n?.supportedLocales ?? const [Locale('en', 'US')],
      home: BootErrorPage(onRetry: _retry, retrying: _retrying),
    );
  }
}
