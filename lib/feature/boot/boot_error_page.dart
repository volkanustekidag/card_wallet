import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

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
    final c = CwColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: CwElevation.e1(context),
                  ),
                  alignment: Alignment.center,
                  child: CwIcon(CwIcons.lock, size: 30, color: c.ink),
                ),
                const SizedBox(height: 20),
                Text('bootErrorTitle'.tr(),
                    textAlign: TextAlign.center,
                    style: CwType.title.copyWith(color: c.ink)),
                const SizedBox(height: 10),
                Text('bootErrorBody'.tr(),
                    textAlign: TextAlign.center,
                    style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
                const SizedBox(height: 28),
                CwButton(
                  'tryAgain'.tr(),
                  key: const Key('bootErrorRetry'),
                  loading: retrying,
                  onPressed: retrying ? null : onRetry,
                ),
                const SizedBox(height: 28),
                Text('bootErrorSupport'.tr(),
                    textAlign: TextAlign.center,
                    style: CwType.footnote.copyWith(color: c.mute)),
                TextButton(
                  onPressed: _openMail,
                  child: Text(supportEmail,
                      style: CwType.callout.copyWith(color: c.accent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
