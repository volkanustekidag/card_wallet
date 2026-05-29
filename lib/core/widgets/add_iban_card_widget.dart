import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';

/// Live preview shown while the user fills the IBAN form. Mirrors the
/// teal-tile look used in the wallet carousel so what they see while
/// typing matches what the home screen will render — same gradient,
/// same chrome, no separate styling.
///
/// [collapse] drives a crossfade between the full card layout (0.0) and a
/// compact pill that just shows bank + last-4 + IBAN tag (1.0). Lets the
/// add page shrink the preview on scroll so the form has room to breathe.
class AddIbanCardWidget extends StatelessWidget {
  final IbanCard ibanCard;
  final double collapse;

  const AddIbanCardWidget({
    Key? key,
    required this.ibanCard,
    this.collapse = 0.0,
  }) : super(key: key);

  static const _gradient = LinearGradient(
    colors: [Color(0xFF0E9F8B), Color(0xFF134E5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _formatIban(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  String _lastFour(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (clean.length < 4) return clean.isEmpty ? '••••' : clean;
    return clean.substring(clean.length - 4);
  }

  bool _hasBankLogo() {
    return CardBankDetector.bankDomainFor(ibanCard.bankName) != null ||
        CardBankDetector.bankDomainFor(
                CardBankDetector.detectFromIban(ibanCard.iban)) !=
            null;
  }

  @override
  Widget build(BuildContext context) {
    final hasIban = ibanCard.iban.trim().isNotEmpty;
    final hasHolder = ibanCard.cardHolder.trim().isNotEmpty;
    final hasBank = ibanCard.bankName.trim().isNotEmpty;
    final t = collapse.clamp(0.0, 1.0);

    // Crossfade: expanded fades out across [0.0, 0.55], compact fades in
    // across [0.45, 1.0]. The slight overlap keeps a hand-off feel rather
    // than a hard pop. Both layouts share the same gradient shell so only
    // the inner content swaps.
    final expandedOpacity = (1 - t / 0.55).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.45) / 0.55).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Expanded layout pinned to the top with its natural 1.586
            // aspect ratio. As the parent shrinks it gets clipped from
            // below, but it's already faded out by then so the clip is
            // invisible.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AspectRatio(
                aspectRatio: 1.586,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: _ExpandedLayout(
                    ibanCard: ibanCard,
                    hasIban: hasIban,
                    hasHolder: hasHolder,
                    hasBank: hasBank,
                    formattedIban: _formatIban(ibanCard.iban),
                    hasLogo: _hasBankLogo(),
                  ),
                ),
              ),
            ),
            // Compact pill: fills whatever height the parent gives.
            Positioned.fill(
              child: Opacity(
                opacity: compactOpacity,
                child: _CompactLayout(
                  ibanCard: ibanCard,
                  hasIban: hasIban,
                  hasBank: hasBank,
                  lastFour: _lastFour(ibanCard.iban),
                  hasLogo: _hasBankLogo(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedLayout extends StatelessWidget {
  final IbanCard ibanCard;
  final bool hasIban;
  final bool hasHolder;
  final bool hasBank;
  final bool hasLogo;
  final String formattedIban;

  const _ExpandedLayout({
    required this.ibanCard,
    required this.hasIban,
    required this.hasHolder,
    required this.hasBank,
    required this.hasLogo,
    required this.formattedIban,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (hasLogo)
                BankLogo(
                  iban: ibanCard.iban,
                  bankName: ibanCard.bankName,
                  size: 20,
                  chrome: true,
                )
              else
                const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasBank ? ibanCard.bankName : 'bName'.tr().toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasBank
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Text(
                'IBAN',
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
                  hasIban ? formattedIban : '•••• •••• •••• •••• ••',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasIban
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  hasHolder
                      ? ibanCard.cardHolder.toUpperCase()
                      : 'holderPlaceholder'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasHolder
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (ibanCard.swiftCode.trim().isNotEmpty)
                Text(
                  ibanCard.swiftCode.toUpperCase(),
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
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final IbanCard ibanCard;
  final bool hasIban;
  final bool hasBank;
  final bool hasLogo;
  final String lastFour;

  const _CompactLayout({
    required this.ibanCard,
    required this.hasIban,
    required this.hasBank,
    required this.hasLogo,
    required this.lastFour,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: hasLogo
                ? BankLogo(
                    iban: ibanCard.iban,
                    bankName: ibanCard.bankName,
                    size: 24,
                  )
                : const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF134E5E),
                    size: 18,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasBank ? ibanCard.bankName : 'bName'.tr().toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasBank
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasIban ? '•• $lastFour' : '•• ••••',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasIban
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'IBAN',
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
    );
  }
}
