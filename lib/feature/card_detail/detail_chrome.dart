import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Back · title · more — the header every card detail page shares.
class DetailTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;

  const DetailTopBar({super.key, required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          CwCircleButton(
            CwIcons.back,
            onPressed: () => Navigator.of(context).maybePop(),
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CwType.headline.copyWith(color: c.ink),
            ),
          ),
          if (onMore != null)
            CwCircleButton(
              CwIcons.more,
              onPressed: onMore,
              semanticLabel: 'cwMore'.tr(),
            )
          else
            const SizedBox(width: 38),
        ],
      ),
    );
  }
}

/// Square-ish tile in the quick-action row under a card.
class QuickActionTile extends StatelessWidget {
  final CwIcons icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(CwRadius.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(CwRadius.m),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CwIcon(icon, size: CwIconSize.m, color: c.ink),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: CwType.caption.copyWith(color: c.ink, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Copies a sensitive value (auto-cleared clipboard) with feedback.
Future<void> copySensitive(
  BuildContext context,
  String value, {
  required String cardType,
}) async {
  await SensitiveClipboard.copy(value, cardType: cardType);
  HapticFeedback.lightImpact();
  if (context.mounted) context.showSuccessSnackBar('cwCopied');
}
