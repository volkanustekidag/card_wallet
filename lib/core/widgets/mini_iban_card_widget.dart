import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';

class MiniIbanCardWidget extends StatelessWidget {
  final IbanCard ibanCard;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCopyTap;
  final VoidCallback? onQRTap;

  const MiniIbanCardWidget({
    Key? key,
    required this.ibanCard,
    this.onTap,
    this.onLongPress,
    this.onCopyTap,
    this.onQRTap,
  }) : super(key: key);

  String _formatIBAN(String iban) {
    // Remove any existing spaces and format in groups of 4
    final cleaned = iban.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardGradient = isDark
        ? [Color(0xFF1F232A), Color(0xFF181B20)]
        : [Color(0xFFFFFBF5), Color(0xFFF3EDE3)];
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFDCD3C6);
    final dividerColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE7DDD0);
    final primaryTextColor =
        isDark ? Colors.white.withOpacity(0.95) : const Color(0xFF11151B);
    final secondaryTextColor =
        isDark ? Colors.white.withOpacity(0.64) : const Color(0xFF7A7F87);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.35) : Colors.black12,
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 168),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ibanCard.cardHolder,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'IBAN',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  secondaryTextColor.withOpacity(0.0),
                                  secondaryTextColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatIBAN(ibanCard.iban),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        letterSpacing: 1.1,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: dividerColor,
                ),
                const SizedBox(height: 10),
                Text(
                  '${ibanCard.bankName} • Swift: ${ibanCard.swiftCode}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.copy,
                        label: 'copy'.tr(),
                        onTap: onCopyTap,
                        color: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.qr_code,
                        label: 'QR',
                        onTap: onQRTap,
                        color: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor.withOpacity(isDark ? 1 : 0.8),
              width: 1,
            ),
            color: isDark
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
