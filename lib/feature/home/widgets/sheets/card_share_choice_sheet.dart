import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

enum CardShareChoice { masked, full }

/// Asks how much of a bank card to share. Masked is listed first; the full
/// number carries an explicit warning.
Future<CardShareChoice?> showCardShareChoiceSheet(
  BuildContext context, {
  required String last4,
}) {
  return showCwSheet<CardShareChoice>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 8),
              child: Text('shareCardTitle'.tr(),
                  style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
            ),
            CwGroup(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                CwRow(
                  leading: CwIconTile(CwIcons.eyeOff, color: c.ok),
                  title: 'shareMaskedOption'.tr(),
                  subtitle: 'shareMaskedSubtitle'.tr(args: [last4]),
                  chevron: true,
                  onTap: () => Navigator.pop(sheet, CardShareChoice.masked),
                ),
                CwRow(
                  leading: CwIconTile(CwIcons.warning, color: c.danger),
                  title: 'shareFullOption'.tr(),
                  subtitle: 'shareFullWarning'.tr(),
                  subtitleColor: c.danger,
                  chevron: true,
                  onTap: () => Navigator.pop(sheet, CardShareChoice.full),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
