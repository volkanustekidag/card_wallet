import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    extends State<NotificationPermissionBanner>
    with WidgetsBindingObserver {
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

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = cs.tertiaryContainer.withValues(alpha: 0.55);
    final fg = cs.onTertiaryContainer;

    return Padding(
      padding: widget.margin,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined, color: fg, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'notificationsDisabledBannerTitle'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'notificationsDisabledBannerBody'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await CardReminderService().openNotificationSettings();
              },
              style: TextButton.styleFrom(
                foregroundColor: fg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: Text(
                'openSettings'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
