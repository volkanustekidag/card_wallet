import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/widgets/iban_card_face.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// IBAN card row used in the dedicated IBAN list page. Renders the same
/// teal-on-navy face as the home featured carousel via [IbanCardFace] so
/// every IBAN looks identical across surfaces. Tap actions (copy, QR, edit,
/// delete) live behind long-press; the row itself is a clean card.
class MiniIbanCardWidget extends StatelessWidget {
  final IbanCard ibanCard;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MiniIbanCardWidget({
    Key? key,
    required this.ibanCard,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AspectRatio(
          aspectRatio: kPaymentCardAspect,
          child: IbanCardFace(
            card: ibanCard,
            boxShadow: kCardShadow,
          ),
        ),
      ),
    );
  }
}
