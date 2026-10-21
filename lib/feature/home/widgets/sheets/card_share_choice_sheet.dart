import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum CardShareChoice { masked, full }

/// Asks how much of a credit card to share. Masked is listed first and is
/// the highlighted option; the full number carries an explicit warning.
Future<CardShareChoice?> showCardShareChoiceSheet(
  BuildContext context, {
  required String last4,
}) {
  return showModalBottomSheet<CardShareChoice>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'shareCardTitle'.tr(),
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.primaryContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.visibility_off_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  title: Text(
                    'shareMaskedOption'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  subtitle: Text(
                    'shareMaskedSubtitle'.tr(args: [last4]),
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(CardShareChoice.masked),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                ),
                title: Text(
                  'shareFullOption'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'shareFullWarning'.tr(),
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(CardShareChoice.full),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text('cancel'.tr()),
              ),
            ],
          ),
        ),
      );
    },
  );
}
