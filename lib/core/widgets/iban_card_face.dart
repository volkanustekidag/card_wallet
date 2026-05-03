import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';

/// The visual face used by every IBAN card in the app — the home featured
/// carousel, the IBAN list, and any future surface that needs to present an
/// IBAN at card-shaped scale. The widget always renders the same teal→navy
/// gradient and 3-row layout (header / IBAN block / footer); callers control
/// the outer dimensions by wrapping with [SizedBox], [AspectRatio], etc.
class IbanCardFace extends StatelessWidget {
  final IbanCard card;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const IbanCardFace({
    Key? key,
    required this.card,
    this.borderRadius = 20,
    this.boxShadow,
  }) : super(key: key);

  static const LinearGradient _gradient = LinearGradient(
    colors: [Color(0xFF0E9F8B), Color(0xFF134E5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final iban = _formatIban(card.iban);
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.6,
        ),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _IbanBankMark(bankName: card.bankName, iban: card.iban),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.bankName.isNotEmpty ? card.bankName : 'IBAN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'ibanCardLabel'.tr().toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IBAN',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      iban,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card.cardHolder.isNotEmpty
                          ? card.cardHolder.toUpperCase()
                          : '----',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (card.swiftCode.isNotEmpty)
                    Text(
                      card.swiftCode.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1,
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

  static String _formatIban(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (clean.isEmpty) return '•••• •••• •••• •••• ••';

    final buffer = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      buffer.write(clean[i]);
      final isLast = i == clean.length - 1;
      if (!isLast && (i + 1) % 4 == 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}

class _IbanBankMark extends StatelessWidget {
  final String bankName;
  final String iban;
  const _IbanBankMark({required this.bankName, required this.iban});

  @override
  Widget build(BuildContext context) {
    final hasLogo = CardBankDetector.bankDomainFor(bankName) != null ||
        CardBankDetector.bankDomainFor(
                CardBankDetector.detectFromIban(iban)) !=
            null;
    if (hasLogo) {
      return BankLogo(
        iban: iban,
        bankName: bankName,
        size: 20,
        chrome: true,
      );
    }
    return const Icon(
      Icons.account_balance_rounded,
      color: Colors.white,
      size: 20,
    );
  }
}
