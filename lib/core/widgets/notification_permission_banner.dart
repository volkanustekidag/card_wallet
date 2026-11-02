import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';

/// Inline banner that surfaces when the OS-level notification permission is
/// off, so the user sees the problem BEFORE saving a card with reminders
/// enabled. Refreshes itself on app resume — fixing the state from Settings
/// makes the banner disappear without a manual reload.
class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({
    Key? key,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  final EdgeInsetsGeometry margin;

  @override
  State<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends State<NotificationPermissionBanner> with WidgetsBindingObserver {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final enabled = await CardReminderService().notificationsEnabled();
    if (!mounted) return;
    if (enabled != _enabled) {
      setState(() => _enabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled != false) return const SizedBox.shrink();

    final c = CwColors.of(context);
    return Padding(
      padding: widget.margin,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: c.warnSoft,
          borderRadius: BorderRadius.circular(CwRadius.m),
        ),
        child: Row(
          children: [
            CwIcon(CwIcons.bell, size: CwIconSize.m, color: c.warn),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('notificationsDisabledBannerTitle'.tr(),
                      style: CwType.callout
                          .copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('notificationsDisabledBannerBody'.tr(),
                      style: CwType.footnote.copyWith(color: c.ink2)),
                ],
              ),
            ),
            TextButton(
              // Asks first (a fresh install was never asked); once the OS
              // won't ask again this offers the system settings instead.
              onPressed: () async {
                await CardReminderService().requestPermission();
                await _refresh();
              },
              child: Text('cwTurnOn'.tr(),
                  style: CwType.footnote
                      .copyWith(color: c.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
