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

/// Hero animation tag prefix used by the carousel and detail/list pages.
String heroTagFor(String kind, dynamic id) => 'home-card-$kind-$id';
