import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';
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
///
/// Returns true when the tutorial was shown.
Future<bool> maybePromptWidgetSetup({
  required int loyaltyCountAfterAdd,
}) async {
  if (loyaltyCountAfterAdd != 1) return false;

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
    if (hasPin) return false;
    try {
      await storage.delete(key: _kWidgetSetupSeenKey);
    } catch (_) {
      // Best-effort; if delete fails the tutorial will show this launch
      // (we fall through) but flag stays stale for next time.
    }
  }

  final context = Get.context;
  if (context == null) return false;

  final platform = Platform.isIOS ? 'ios' : 'android';
  unawaited(AnalyticsService.instance.logWidgetSetupShown(platform));

  final acknowledged = await showCwSheet<bool>(
    context,
    builder: (_) => const _WidgetSetupSheet(),
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
  return true;
}

class _WidgetSetupSheet extends StatelessWidget {
  const _WidgetSetupSheet();

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final isIOS = Platform.isIOS;
    final steps = isIOS
        ? const ['widgetSetupiOSStep1', 'widgetSetupiOSStep2', 'widgetSetupiOSStep3']
        : const [
            'widgetSetupAndroidStep1',
            'widgetSetupAndroidStep2',
            'widgetSetupAndroidStep3',
          ];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: CwIcon(CwIcons.grid, size: 26, color: c.accent),
              ),
            ),
            const SizedBox(height: 14),
            Text('widgetSetupTitle'.tr(),
                textAlign: TextAlign.center,
                style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
            const SizedBox(height: 6),
            Text('widgetSetupSubtitle'.tr(),
                textAlign: TextAlign.center,
                style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
            const SizedBox(height: 18),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration:
                          BoxDecoration(color: c.ink, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: CwType.caption.copyWith(color: c.bg)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(steps[i].tr(),
                          style: CwType.callout.copyWith(color: c.ink)),
                    ),
                  ],
                ),
              ),
            if (isIOS) ...[
              const SizedBox(height: 6),
              CwNotice.info(context, 'widgetSetupWatchHint'.tr()),
            ],
            const SizedBox(height: 18),
            CwButton('widgetSetupGotIt'.tr(),
                onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: 6),
            CwButton.ghost('widgetSetupLater'.tr(),
                onPressed: () => Navigator.pop(context, false)),
          ],
        ),
      ),
    );
  }
}
