import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown instead of the app when the critical init (auth box) failed —
/// usually because the Keychain / Keystore can't be read right now. There is
/// deliberately no "reset data" action: the cards on disk are intact.
class BootErrorPage extends StatelessWidget {
  static const String supportEmail = 'volkanustekidg@gmail.com';

  final Future<void> Function() onRetry;
  final bool retrying;

  const BootErrorPage({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });

  Future<void> _openMail() async {
    await launchUrl(
      Uri(scheme: 'mailto', path: supportEmail),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'bootErrorTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'bootErrorBody'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('bootErrorRetry'),
                    onPressed: retrying ? null : onRetry,
                    child: retrying
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('tryAgain'.tr()),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'bootErrorSupport'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: _openMail,
                  child: const Text(supportEmail),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
