import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// Persisted across launches so we don't re-show the tutorial every time a
/// loyalty card is added. Either "Got it" or "Later" flips this — the goal
/// is one impression per device; Settings can later expose a "show tutorial
/// again" hook if we add it.
const String _kWidgetSetupSeenKey = 'widget_setup_seen';

/// In-app tutorial nudge shown after the user adds their first loyalty card.
/// The point: most users never discover the home-screen widget or Apple Watch
/// integration on their own, and people who *do* install the widget churn far
/// less because the card lives on their phone's main screen.
///
/// Three guards keep this from becoming naggy:
///   1. The user just added their first loyalty card
///      (`loyaltyCountAfterAdd == 1`).
///   2. They haven't already seen the tutorial (persisted flag).
///   3. A live BuildContext is available (no-op otherwise).
Future<void> maybePromptWidgetSetup({
  required int loyaltyCountAfterAdd,
}) async {
  if (loyaltyCountAfterAdd != 1) return;

  const storage = SecureStorageProvider.instance;
  String? seen;
  try {
    seen = await storage.read(key: _kWidgetSetupSeenKey);
  } catch (_) {
    seen = null;
  }
  if (seen == 'true') {
    // iOS keeps Keychain entries across uninstalls. If the user has no
    // PIN (auth box wiped = effectively a fresh install) but this flag
    // is still set, treat it as stale and re-show the tutorial. False
    // positive: a long-time PIN-less user re-sees the tutorial once —
    // acceptable trade-off given the tutorial is informational and the
    // value of showing it to true fresh installs is high (widget
    // adoption is the single biggest retention lever we have).
    final hasPin = AuthenticationService().hasPasswordSync();
    if (hasPin) return;
    try {
      await storage.delete(key: _kWidgetSetupSeenKey);
    } catch (_) {
      // Best-effort; if delete fails the tutorial will show this launch
      // (we fall through) but flag stays stale for next time.
    }
  }

  final context = Get.context;
  if (context == null) return;

  final platform = Platform.isIOS ? 'ios' : 'android';
  unawaited(AnalyticsService.instance.logWidgetSetupShown(platform));

  final acknowledged = await Get.dialog<bool>(
    const _WidgetSetupDialog(),
    barrierDismissible: true,
  );

  if (acknowledged == true) {
    unawaited(AnalyticsService.instance.logWidgetSetupAcknowledged());
  } else {
    unawaited(AnalyticsService.instance.logWidgetSetupDeferred());
  }

  try {
    await storage.write(key: _kWidgetSetupSeenKey, value: 'true');
  } catch (_) {
    // Best-effort; worst case we ask one more time on the next loyalty add.
  }
}

class _WidgetSetupDialog extends StatelessWidget {
  const _WidgetSetupDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIOS = Platform.isIOS;
    final steps = isIOS
        ? const [
            'widgetSetupiOSStep1',
            'widgetSetupiOSStep2',
            'widgetSetupiOSStep3',
          ]
        : const [
            'widgetSetupAndroidStep1',
            'widgetSetupAndroidStep2',
            'widgetSetupAndroidStep3',
          ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'widgetSetupTitle'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'widgetSetupSubtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  height: 1.4,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < steps.length; i++) ...[
                _StepRow(index: i + 1, labelKey: steps[i]),
                if (i < steps.length - 1) const SizedBox(height: 10),
              ],
              if (isIOS) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.watch_rounded,
                        size: 18,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'widgetSetupWatchHint'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back<bool>(result: false),
                    child: Text(
                      'widgetSetupLater'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => Get.back<bool>(result: true),
                    child: Text(
                      'widgetSetupGotIt'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String labelKey;

  const _StepRow({required this.index, required this.labelKey});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              labelKey.tr(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
