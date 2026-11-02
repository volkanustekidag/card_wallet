import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_formats.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart'
    show formatBarcodeText;
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';
import 'package:wallet_app/ui/card/card_face.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/typography.dart';

/// A loyalty card as it will look in the wallet, with its barcode drawn —
/// used by the scan confirmation and the manual form.
class LoyaltyCardPreview extends StatelessWidget {
  final LoyaltyCard card;
  const LoyaltyCardPreview({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final item = WalletItem.loyalty(card);
    final square = isSquareBarcodeFormat(card.barcodeFormat);
    final hasCode = card.barcode.trim().isNotEmpty;
    return CardFace(
      material: materialForItem(item),
      interactive: true,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardStripHeader(item: item, trailing: const SizedBox()),
          const SizedBox(height: 14),
          Container(
            height: square ? 150 : 104,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasCode
                ? Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: BarcodeRenderer(
                            data: card.barcode,
                            format: card.barcodeFormat,
                            qrSize: 104,
                            barcodeHeight: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatBarcodeText(card.barcode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CwType.mono(
                          size: square ? 11 : 12.5,
                          color: const Color(0xFF111215),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '0000 0000 0000',
                      style: CwType.mono(
                        size: 14,
                        color: const Color(0xFFB0B3BA),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
