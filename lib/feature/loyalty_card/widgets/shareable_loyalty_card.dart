import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';

/// Print-quality loyalty card laid out for sharing as a PNG. Larger than
/// the wallet preview so the barcode is still scannable when the recipient
/// only has the image (no need to forward the raw number). The white
/// barcode area is always rendered on a solid card so OS share sheets
/// don't paint a dark backdrop behind the bars and break decoding.
class ShareableLoyaltyCard extends StatelessWidget {
  final LoyaltyCard card;

  /// Pre-resolved brand logo provider. Pass the result of
  /// [precacheBrandLogo]. When non-null we render via [Image] directly so
  /// the off-screen snapshot never has to wait on a network round-trip
  /// or a [CachedNetworkImage] state-machine — this is what keeps the
  /// exported PNG looking as crisp as the in-app rendering.
  final ImageProvider? brandLogoImage;

  /// Logical edge size of the rendered card (pixel ratio is applied at
  /// capture time). The 1.6 aspect mirrors the wallet's payment-card ratio.
  static const double width = 720;
  static const double height = 1100;

  const ShareableLoyaltyCard({
    Key? key,
    required this.card,
    this.brandLogoImage,
  }) : super(key: key);

  /// Resolves the brand logo into Flutter's image cache and returns the
  /// [ImageProvider] so callers can inject it into [ShareableLoyaltyCard]
  /// with [brandLogoImage]. Without this injection the snapshot pipeline
  /// fires before [CachedNetworkImage]'s internal state machine settles,
  /// producing a washed-out / dimmed logo.
  ///
  /// Returns `null` when the brand isn't mapped or the network fetch
  /// fails — share path falls back to the fallback glyph.
  static Future<ImageProvider?> precacheBrandLogo(
    BuildContext context,
    LoyaltyCard card,
  ) async {
    final brand = (card.brand?.isNotEmpty ?? false) ? card.brand! : card.name;
    final domain = LoyaltyBrandResolver.domainFor(brand);
    if (domain == null) return null;
    final url = 'https://t3.gstatic.com/faviconV2'
        '?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL'
        '&url=http://$domain&size=128';
    final provider = CachedNetworkImageProvider(url);
    try {
      // ignore: use_build_context_synchronously
      await precacheImage(provider, context);
      return provider;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradients = LinearGradients().linearGradientList;
    final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
    final brand = (card.brand?.isNotEmpty ?? false) ? card.brand! : card.name;
    final hasBrandLogo = brandLogoImage != null;
    final isQr = card.barcodeFormat == 'QR_CODE';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(48),
      ),
      padding: const EdgeInsets.fromLTRB(56, 56, 56, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasBrandLogo) ...[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Image(
                    image: brandLogoImage!,
                    width: 68,
                    height: 68,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 24),
              ] else ...[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(width: 24),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.name.isNotEmpty ? card.name : brand,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    if (brand.isNotEmpty && brand != card.name) ...[
                      const SizedBox(height: 8),
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // White panel hosting the barcode/QR. White background is
          // mandatory for reliable scanner reads — never tint this.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BarcodeRenderer(
                  data: card.barcode,
                  format: card.barcodeFormat,
                  qrSize: 360,
                  barcodeHeight: 200,
                ),
                const SizedBox(height: 18),
                Text(
                  card.barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D24),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isQr ? 'QR CODE' : card.barcodeFormat.replaceAll('_', ' '),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: const Color(0xFF1A1D24).withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOYALTY CARD',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'Card Wallet',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
