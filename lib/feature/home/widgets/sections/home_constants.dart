import 'package:flutter/material.dart';

/// 8-dp baseline grid tokens used across the redesigned home page.
const double kSpaceXS = 4;
const double kSpaceSm = 8;
const double kSpaceMd = 12;
const double kSpaceLg = 16;
const double kSpaceXL = 24;
const double kSpaceXXL = 32;

/// Hero header layout. Slim now that the stat-chip row is gone:
///   collapsed bar (64) + 4 gap + greeting (~30) + 4 + subline (~18)
///   + 12 bottom padding ≈ 132 dp. Wallet-like calm rather than a
///   dashboard with stats.
const double kHeroExpandedHeight = 138;
const double kHeroCollapsedHeight = 64;

/// Card carousel.
const double kCarouselViewport = 0.86;
const double kCarouselItemGap = 6;
const double kCarouselDotSize = 6;
const double kCarouselDotActiveWidth = 18;

/// Common card aspect ratios used inside shelves.
const double kPaymentCardAspect = 1.58;

/// Shelf header height + carousel heights per kind.
const double kShelfHeaderHeight = 44;
const double kCcCarouselHeight = 220;
const double kIbanCarouselHeight = 168;
const double kLoyaltyCarouselHeight = 110;

/// Premium status strip.
const double kStripCollapsedHeight = 0;
const double kStripExpandedHeight = 56;

/// Smart suggestion card.
const double kSuggestionHeight = 88;

/// Quick action rail.
const double kQuickActionRailHeight = 88;
const double kQuickActionTileSize = 56;

/// Welcome stack (0-card empty state).
const double kWelcomeStackHeight = 280;
const double kWelcomeCardWidth = 220;

/// Animation durations and curves shared across home widgets.
const Duration kFastAnim = Duration(milliseconds: 100);
const Duration kMediumAnim = Duration(milliseconds: 240);
const Duration kSlowAnim = Duration(milliseconds: 320);
const Curve kHomeCurve = Curves.easeOutCubic;

/// Reverse-parallax for the filter chips + recent cards panel. As the user
/// scrolls past [kBottomFocusStart] the panel begins expanding (chips and
/// rows grow, container lifts), reaching its peak at [kBottomFocusEnd].
/// The values pair with the carousel's tilt threshold so the bottom panel
/// "wakes up" right as the carousel starts to slip out of view.
const double kBottomFocusStart = 200;
const double kBottomFocusEnd = 420;

/// Maps [offset] to a 0..1 prominence score using the focus thresholds.
/// 0 = collapsed/compact (top-of-page state), 1 = fully expanded
/// (bottom-of-page focus state).
double bottomPanelProminence(double offset) {
  if (offset <= kBottomFocusStart) return 0;
  if (offset >= kBottomFocusEnd) return 1;
  return (offset - kBottomFocusStart) / (kBottomFocusEnd - kBottomFocusStart);
}

/// Hero animation tag prefix used by the carousel and detail/list pages.
String heroTagFor(String kind, dynamic id) => 'home-card-$kind-$id';

/// Two-layer drop shadow shared by all card surfaces in the home carousel.
/// A small, near shadow grounds the card; a larger, softer shadow gives it
/// elevation. Sized so the carousel breathing room (kCardShadowGutter) fits
/// the bloom without clipping.
const List<BoxShadow> kCardShadow = [
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
];

/// Vertical breathing room added below the card area so [kCardShadow]
/// renders fully instead of being clipped by the carousel viewport.
const double kCardShadowGutter = 56;
