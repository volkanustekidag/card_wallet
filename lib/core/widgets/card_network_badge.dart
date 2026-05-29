import 'package:flutter/material.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';

/// Renders the network's recognisable logo. Asset-first: looks for a PNG at
/// `assets/icons/networks/<name>.png`; if that asset is missing we fall back
/// to a wordmark / Mastercard custom-paint so the card never shows a broken
/// image. Expected assets (transparent PNGs):
///   visa, mastercard, amex, unionpay, discover, jcb, troy.
/// Diners Club intentionally renders as a wordmark only — it's niche enough
/// that adding an asset isn't worth the trademark caution.
class CardNetworkBadge extends StatelessWidget {
  final CardNetwork network;
  final double height;

  const CardNetworkBadge({
    Key? key,
    required this.network,
    this.height = 22,
  }) : super(key: key);

  String? get _assetPath {
    switch (network) {
      case CardNetwork.visa:
        return 'assets/icons/networks/visa.png';
      case CardNetwork.mastercard:
        return 'assets/icons/networks/mastercard.png';
      case CardNetwork.amex:
        return 'assets/icons/networks/amex.png';
      case CardNetwork.unionPay:
        return 'assets/icons/networks/unionpay.png';
      case CardNetwork.discover:
        return 'assets/icons/networks/discover.png';
      case CardNetwork.jcb:
        return 'assets/icons/networks/jcb.png';
      case CardNetwork.troy:
        return 'assets/icons/networks/troy.png';
      case CardNetwork.dinersClub:
      case CardNetwork.unknown:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (network == CardNetwork.unknown) return const SizedBox.shrink();

    final asset = _assetPath;
    if (asset != null) {
      return Image.asset(
        asset,
        height: height,
        fit: BoxFit.contain,
        // If the user hasn't dropped the PNG in yet, render the legacy
        // fallback so the card still gets a network mark.
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    switch (network) {
      case CardNetwork.mastercard:
        return SizedBox(
          width: height * 1.55,
          height: height,
          child: const CustomPaint(painter: _MastercardPainter()),
        );
      case CardNetwork.visa:
        return Text(
          'VISA',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
            fontSize: height * 0.86,
            color: Colors.white,
            letterSpacing: 2,
            height: 1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        );
      case CardNetwork.troy:
        return _Wordmark(label: 'TROY', height: height);
      case CardNetwork.amex:
        return _Wordmark(label: 'AMEX', height: height);
      case CardNetwork.unionPay:
        return _Wordmark(label: 'UNIONPAY', height: height);
      case CardNetwork.discover:
        return _Wordmark(label: 'DISCOVER', height: height);
      case CardNetwork.dinersClub:
        return _Wordmark(label: 'DINERS', height: height);
      case CardNetwork.jcb:
        return _Wordmark(label: 'JCB', height: height);
      case CardNetwork.unknown:
        return const SizedBox.shrink();
    }
  }
}

/// Simple white wordmark with a subtle drop shadow so it reads on any
/// gradient. Used for networks whose actual logos are too detailed to
/// reproduce trademark-cleanly with primitives.
class _Wordmark extends StatelessWidget {
  final String label;
  final double height;
  const _Wordmark({required this.label, required this.height});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        fontSize: height * 0.7,
        color: Colors.white,
        letterSpacing: 1.6,
        height: 1,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

/// Two overlapping circles: red on the left, yellow on the right, with an
/// orange wedge where they overlap. The classic Mastercard mark.
class _MastercardPainter extends CustomPainter {
  const _MastercardPainter();

  static const _red = Color(0xFFEB001B);
  static const _yellow = Color(0xFFF79E1B);
  static const _orange = Color(0xFFFF5F00);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final cy = size.height / 2;
    // The two circles overlap by ~25% of their diameter so the orange
    // wedge in the middle is visible without dominating.
    final cx1 = r;
    final cx2 = size.width - r;

    final redPaint = Paint()..color = _red;
    final yellowPaint = Paint()..color = _yellow;
    final orangePaint = Paint()..color = _orange;

    canvas.drawCircle(Offset(cx1, cy), r, redPaint);
    canvas.drawCircle(Offset(cx2, cy), r, yellowPaint);

    // Clip the canvas to the red circle, then draw the yellow on top —
    // their intersection picks up the orange wedge colour.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx1, cy), radius: r)),
    );
    canvas.drawCircle(Offset(cx2, cy), r, orangePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
