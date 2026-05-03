import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Bottom sheet shown when "Share IBAN" is tapped and the user has more
/// than one IBAN. Lists each IBAN with a compact preview; tapping pops the
/// sheet with the chosen card so the caller can hand it to share_plus.
Future<IbanCard?> showIbanPickerSheet({
  required BuildContext context,
  required List<IbanCard> ibans,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<IbanCard>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _IbanPickerSheet(ibans: ibans),
  );
}

class _IbanPickerSheet extends StatelessWidget {
  final List<IbanCard> ibans;
  const _IbanPickerSheet({required this.ibans});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpaceLg,
          vertical: kSpaceMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: kSpaceMd),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'pickIbanToShare'.tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: kSpaceMd),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ibans.length,
                separatorBuilder: (_, __) => const SizedBox(height: kSpaceSm),
                itemBuilder: (_, i) => _IbanRow(
                  card: ibans[i],
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, ibans[i]);
                  },
                ),
              ),
            ),
            const SizedBox(height: kSpaceSm),
          ],
        ),
      ),
    );
  }
}

class _IbanRow extends StatelessWidget {
  final IbanCard card;
  final VoidCallback onTap;
  const _IbanRow({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceMd,
            vertical: kSpaceMd,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: kSpaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _maskedIban(card.iban),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.bankName.isNotEmpty
                          ? '${card.bankName} • ${card.cardHolder}'
                          : card.cardHolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskedIban(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (clean.length < 8) return clean;
    final head = clean.substring(0, 4);
    final tail = clean.substring(clean.length - 4);
    return '$head •••• •••• •••• $tail';
  }
}
