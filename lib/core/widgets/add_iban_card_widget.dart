import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:easy_localization/easy_localization.dart';

class AddIbanCardWidget extends StatelessWidget {
  final IbanCard ibanCard;

  const AddIbanCardWidget({Key? key, required this.ibanCard}) : super(key: key);

  String _formatIban(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  String _fallback(String value, String placeholder) {
    if (value.trim().isEmpty) {
      return placeholder;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasIban = ibanCard.iban.trim().isNotEmpty;
    final hasHolder = ibanCard.cardHolder.trim().isNotEmpty;
    final glowColor =
        theme.colorScheme.primary.withOpacity(hasIban ? 0.28 : 0.12);
    final accentColor = theme.colorScheme.secondary.withOpacity(0.6);

    final surfaceOverlay = isDark
        ? Colors.white.withOpacity(0.06)
        : theme.colorScheme.onSurface.withOpacity(0.05);
    final baseTextColor =
        isDark ? Colors.white : theme.colorScheme.onPrimaryContainer;
    final secondaryTextColor =
        isDark ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.72);
    final placeholderBackground = isDark
        ? Colors.white.withOpacity(0.03)
        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.9);
    final placeholderBorder = isDark
        ? Colors.white.withOpacity(0.04)
        : theme.colorScheme.outlineVariant.withOpacity(0.4);
    final infoPillBackground = isDark
        ? Colors.white.withOpacity(0.05)
        : theme.colorScheme.onSurface.withOpacity(0.04);
    final infoPillBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : theme.colorScheme.outlineVariant.withOpacity(0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: hasIban ? 240 : 190,
        maxWidth: 520,
      ),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            glowColor,
            theme.colorScheme.primary.withOpacity(hasIban ? 0.16 : 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ibanPreview'.tr(),
                    style: TextStyle(fontFamily: 'Poppins', 
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: baseTextColor.withOpacity(0.9),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: surfaceOverlay,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 14, color: secondaryTextColor),
                        const SizedBox(width: 6),
                        Text(
                          'secure'.tr(),
                          style: TextStyle(fontFamily: 'Poppins', 
                            fontSize: 11,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                fit: FlexFit.loose,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: hasIban
                      ? _buildFilledPreview(
                          context,
                          accentColor: accentColor,
                          hasHolder: hasHolder,
                          primaryTextColor: baseTextColor,
                          secondaryTextColor: secondaryTextColor,
                          infoBackground: infoPillBackground,
                          infoBorderColor: infoPillBorder,
                        )
                      : _buildPlaceholder(
                          textColor: baseTextColor,
                          secondaryTextColor: secondaryTextColor,
                          backgroundColor: placeholderBackground,
                          borderColor: placeholderBorder,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder({
    required Color textColor,
    required Color secondaryTextColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      key: const ValueKey('placeholder'),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ibanPreviewPlaceholder'.tr(),
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 13,
                color: textColor.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ibanFlowHint'.tr(),
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 12,
                color: secondaryTextColor.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledPreview(
    BuildContext context, {
    required Color accentColor,
    required bool hasHolder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color infoBackground,
    required Color infoBorderColor,
  }) {
    return Column(
      key: const ValueKey('filled'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IBAN',
          style: TextStyle(fontFamily: 'Poppins', 
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatIban(ibanCard.iban),
          style: TextStyle(fontFamily: 'Poppins', 
            fontSize: 18,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 18),
        Text(
          hasHolder ? ibanCard.cardHolder : 'holderPlaceholder'.tr(),
          style: TextStyle(fontFamily: 'Poppins', 
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                primaryTextColor.withOpacity(0.15),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoPill(
                label: 'bName'.tr(),
                value: _fallback(
                  ibanCard.bankName,
                  'placeholderValue'.tr(),
                ),
                backgroundColor: infoBackground,
                borderColor: infoBorderColor,
                textColor: primaryTextColor,
                captionColor: secondaryTextColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoPill(
                label: 'sCode'.tr(),
                value: _fallback(
                  ibanCard.swiftCode,
                  'placeholderValue'.tr(),
                ),
                backgroundColor: infoBackground,
                borderColor: infoBorderColor,
                textColor: primaryTextColor,
                captionColor: secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color captionColor;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Poppins', 
              fontSize: 11,
              color: captionColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontFamily: 'Poppins', 
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
