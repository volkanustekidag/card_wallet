import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:hive/hive.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// One-time intro shown before the home (or PIN, for migrated users) on
/// first launch. Single screen with an auto-rotating feature card so the
/// pitch reads as a quick teaser rather than a four-tap slideshow. The
/// `onboarding_seen` flag in a Hive box gates re-display; a re-install
/// brings it back because Hive boxes live in the app's documents directory
/// and are wiped on uninstall on both iOS and Android.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  static const String storageKey = 'onboarding_seen';
  static const String _boxName = 'app_state';

  // Earlier builds wrote the flag to FlutterSecureStorage. iOS Keychain
  // survives uninstall, so a "no PIN ⇒ fresh install" heuristic was used
  // to force re-display on reinstall — but PIN is opt-in, so the majority
  // of users (who skip PIN) re-saw onboarding every launch. We migrated to
  // Hive (wiped on uninstall) and clean up the stale Keychain entry once.
  static bool _legacyCleanedUp = false;

  static Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return Hive.openBox<dynamic>(_boxName);
  }

  static Future<bool> shouldShow() async {
    try {
      final box = await _openBox();
      final seen = box.get(storageKey) == true;
      _cleanupLegacyFlag();
      return !seen;
    } catch (_) {
      return false;
    }
  }

  static void _cleanupLegacyFlag() {
    if (_legacyCleanedUp) return;
    _legacyCleanedUp = true;
    unawaited(
      SecureStorageProvider.instance.delete(key: storageKey).catchError((_) {}),
    );
  }

  static Future<void> _markSeen() async {
    try {
      final box = await _openBox();
      await box.put(storageKey, true);
    } catch (_) {
      // best-effort
    }
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  // 6 slides * 3.2s ≈ 19s full cycle. Long enough to read each, short
  // enough that a passive viewer sees every feature before the CTA tap.
  static const Duration _rotationInterval = Duration(milliseconds: 3200);

  // Built in initState so Platform.isIOS can swap the wallet/extras slides.
  // Slides 1-3 are platform-agnostic value props; 4 is cross-platform OCR;
  // 5 and 6 branch on platform (Apple Wallet/Watch+Widgets vs Google
  // Wallet/Home Widget+Tile).
  late final List<_OnboardingFeature> _features;

  static List<_OnboardingFeature> _buildFeatures() {
    final isIos = Platform.isIOS;
    return [
      const _OnboardingFeature(
        icon: Icons.style_rounded,
        titleKey: 'onboardingSlide1Title',
        descKey: 'onboardingSlide1Desc',
        accent: Color(0xFF4568DC),
        cardKind: _CardKind.credit,
      ),
      const _OnboardingFeature(
        icon: Icons.lock_rounded,
        titleKey: 'onboardingSlide2Title',
        descKey: 'onboardingSlide2Desc',
        accent: Color(0xFF11998E),
        cardKind: _CardKind.iban,
      ),
      const _OnboardingFeature(
        icon: Icons.fingerprint_rounded,
        titleKey: 'onboardingSlide3Title',
        descKey: 'onboardingSlide3Desc',
        accent: Color(0xFFFF6A00),
        cardKind: _CardKind.loyalty,
      ),
      const _OnboardingFeature(
        icon: Icons.qr_code_scanner_rounded,
        titleKey: 'onboardingSlide4Title',
        descKey: 'onboardingSlide4Desc',
        accent: Color(0xFF9B59B6),
        cardKind: _CardKind.credit,
      ),
      _OnboardingFeature(
        icon: Icons.account_balance_wallet_rounded,
        titleKey:
            isIos ? 'onboardingSlide5IosTitle' : 'onboardingSlide5AndroidTitle',
        descKey:
            isIos ? 'onboardingSlide5IosDesc' : 'onboardingSlide5AndroidDesc',
        accent: const Color(0xFF6F2DBD),
        cardKind: _CardKind.loyalty,
      ),
      _OnboardingFeature(
        icon: isIos ? Icons.watch_outlined : Icons.widgets_rounded,
        titleKey:
            isIos ? 'onboardingSlide6IosTitle' : 'onboardingSlide6AndroidTitle',
        descKey:
            isIos ? 'onboardingSlide6IosDesc' : 'onboardingSlide6AndroidDesc',
        accent: const Color(0xFFE91E63),
        cardKind: _CardKind.loyalty,
      ),
    ];
  }

  Timer? _ticker;
  int _currentIndex = 0;

  // Cached so build() and _handlePrimaryCta() don't hit the auth box on every
  // rebuild. Resolved once in initState — `hasPasswordSync` requires the auth
  // box to be open, which main.dart guarantees before runApp.
  late final bool _hasPassword;

  late final AnimationController _floatController;
  late final AnimationController _shimmerController;
  late final AnimationController _ctaPulseController;

  @override
  void initState() {
    super.initState();
    _features = _buildFeatures();
    _hasPassword = AuthenticationService().hasPasswordSync();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _ctaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _ticker = Timer.periodic(_rotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _features.length;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _floatController.dispose();
    _shimmerController.dispose();
    _ctaPulseController.dispose();
    super.dispose();
  }

  // Double-tap guard. iOS Keychain write + route transition can take a
  // beat on cold launch; without this a frustrated second tap fires a
  // duplicate offAllNamed which GetX serialises and stutters through.
  bool _finishing = false;

  /// [openAddCardSheet] only matters for fresh users — migrated users with a
  /// PIN always land on /auth regardless. Default true because the primary
  /// CTA is "Add your first card"; the "Skip for now" link passes false.
  Future<void> _finish({bool openAddCardSheet = true}) async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    // Keychain write is fire-and-forget — blocking the route transition on
    // a 100–300ms iOS Keychain round-trip is what makes the CTA feel laggy.
    // If the user kills the app before the write lands they re-see the
    // intro on next launch, which is fine.
    unawaited(OnboardingPage._markSeen());
    unawaited(AnalyticsService.instance.logOnboardingComplete());
    if (!openAddCardSheet) {
      unawaited(
        AnalyticsService.instance.logEvent('first_card_picker_skipped'),
      );
    }
    if (!mounted) return;
    // Existing users (with PIN) still see the lock screen; new users go
    // straight to home and may set up a PIN later.
    if (_hasPassword) {
      Get.offAllNamed(AppRoutes.auth);
      return;
    }
    Get.offAllNamed(
      AppRoutes.home,
      arguments: openAddCardSheet ? {'open_add_card_sheet': true} : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final feature = _features[_currentIndex];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: _AnimatedBackdrop(accent: feature.accent, isDark: isDark),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                _CardStackHero(
                  feature: feature,
                  floatController: _floatController,
                  shimmerController: _shimmerController,
                ),
                const SizedBox(height: 48),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'onboardingHeroTitle'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offset = Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
                        );
                      },
                      child: _FeatureBlock(
                        key: ValueKey(feature.titleKey),
                        feature: feature,
                        pulseController: _floatController,
                      ),
                    ),
                  ),
                ),
                _Indicators(
                  count: _features.length,
                  activeIndex: _currentIndex,
                  accent: feature.accent,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 18),
                _CtaButton(
                  label: (_hasPassword
                          ? 'onboardingStart'
                          : 'onboardingAddFirstCard')
                      .tr(),
                  pulseController: _ctaPulseController,
                  onPressed: () => _finish(),
                ),
                if (!_hasPassword) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => _finish(openAddCardSheet: false),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          colorScheme.onSurface.withValues(alpha: 0.65),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text('onboardingSkipForNow'.tr()),
                  ),
                ],
                const SizedBox(height: 24),
                const _TrustSignals(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum _CardKind { credit, iban, loyalty }

class _OnboardingFeature {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final Color accent;
  final _CardKind cardKind;
  const _OnboardingFeature({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.accent,
    required this.cardKind,
  });
}

// ---------------------------------------------------------------------------
// Backdrop — radial glow that re-tints with the active slide.
// ---------------------------------------------------------------------------

class _AnimatedBackdrop extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _AnimatedBackdrop({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.65),
          radius: 1.1,
          colors: isDark
              ? [
                  accent.withValues(alpha: 0.45),
                  accent.withValues(alpha: 0.16),
                  Colors.transparent,
                ]
              : [
                  accent.withValues(alpha: 0.32),
                  accent.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
          stops: const [0, 0.55, 1],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card stack hero — three rotated mock cards. Front card carries a shimmer
// sweep and the whole stack drifts vertically with a slow sine.
// ---------------------------------------------------------------------------

class _CardStackHero extends StatelessWidget {
  final _OnboardingFeature feature;
  final AnimationController floatController;
  final AnimationController shimmerController;
  const _CardStackHero({
    required this.feature,
    required this.floatController,
    required this.shimmerController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.58).clamp(200.0, 300.0);
    final cardHeight = cardWidth / 1.586; // ISO 7810

    return SizedBox(
      height: cardHeight + 36,
      child: AnimatedBuilder(
        animation: floatController,
        builder: (_, __) {
          final t = floatController.value; // 0..1..0
          final dy = math.sin(t * math.pi) * 6 - 3;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Left peek
                Transform.translate(
                  offset: Offset(-cardWidth * 0.40, 10),
                  child: Transform.rotate(
                    angle: -0.10,
                    child: Opacity(
                      opacity: 0.55,
                      child: _MockCard(
                        width: cardWidth,
                        height: cardHeight,
                        gradient: _gradientFor(_peekKindLeft(feature.cardKind)),
                        kind: _peekKindLeft(feature.cardKind),
                      ),
                    ),
                  ),
                ),
                // Right peek
                Transform.translate(
                  offset: Offset(cardWidth * 0.40, 10),
                  child: Transform.rotate(
                    angle: 0.10,
                    child: Opacity(
                      opacity: 0.55,
                      child: _MockCard(
                        width: cardWidth,
                        height: cardHeight,
                        gradient:
                            _gradientFor(_peekKindRight(feature.cardKind)),
                        kind: _peekKindRight(feature.cardKind),
                      ),
                    ),
                  ),
                ),
                // Front card with shimmer
                AnimatedBuilder(
                  animation: shimmerController,
                  builder: (_, __) {
                    return Stack(
                      children: [
                        _MockCard(
                          width: cardWidth,
                          height: cardHeight,
                          gradient: _gradientFor(feature.cardKind),
                          kind: feature.cardKind,
                          isFront: true,
                        ),
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CustomPaint(
                              painter: _ShimmerPainter(
                                progress: shimmerController.value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static _CardKind _peekKindLeft(_CardKind front) {
    switch (front) {
      case _CardKind.credit:
        return _CardKind.iban;
      case _CardKind.iban:
        return _CardKind.loyalty;
      case _CardKind.loyalty:
        return _CardKind.credit;
    }
  }

  static _CardKind _peekKindRight(_CardKind front) {
    switch (front) {
      case _CardKind.credit:
        return _CardKind.loyalty;
      case _CardKind.iban:
        return _CardKind.credit;
      case _CardKind.loyalty:
        return _CardKind.iban;
    }
  }

  static LinearGradient _gradientFor(_CardKind kind) {
    switch (kind) {
      case _CardKind.credit:
        return const LinearGradient(
          colors: [Color(0xFF4568DC), Color(0xFF2B3F8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case _CardKind.iban:
        return const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF0B5C56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case _CardKind.loyalty:
        return const LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFC25116)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

class _MockCard extends StatelessWidget {
  final double width;
  final double height;
  final LinearGradient gradient;
  final _CardKind kind;
  final bool isFront;

  const _MockCard({
    required this.width,
    required this.height,
    required this.gradient,
    required this.kind,
    this.isFront = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isFront ? 0.30 : 0.12,
            ),
            blurRadius: isFront ? 26 : 14,
            offset: Offset(0, isFront ? 14 : 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: _MockCardContent(kind: kind),
      ),
    );
  }
}

class _MockCardContent extends StatelessWidget {
  final _CardKind kind;
  const _MockCardContent({required this.kind});

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _CardKind.credit:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFEAC76C),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Spacer(),
            Text(
              '•••• •••• •••• 4242',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'CARDHOLDER',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.contactless_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 16,
                ),
              ],
            ),
          ],
        );
      case _CardKind.iban:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IBAN',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            Text(
              'TR12 3456 •••• 6543',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'CARDHOLDER',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        );
      case _CardKind.loyalty:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'LOYALTY',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Faux barcode strip
            SizedBox(
              height: 18,
              child: Row(
                children: List.generate(28, (i) {
                  final isWide = i % 3 == 0;
                  return Container(
                    width: isWide ? 3 : 1.5,
                    margin: const EdgeInsets.only(right: 2),
                    color: Colors.white.withValues(
                      alpha: i.isEven ? 0.95 : 0.55,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '•••• 0429',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        );
    }
  }
}

/// Diagonal white sweep, ported from the paywall's _ShimmerPainter. Travels
/// across the front card during the first ~35% of the cycle, then idles.
class _ShimmerPainter extends CustomPainter {
  final double progress;
  const _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.35) return;
    final t = progress / 0.35;
    final shineWidth = size.width * 0.30;
    final dx = -shineWidth + (size.width + shineWidth * 2) * t;
    final rect = Rect.fromLTWH(
      dx,
      -size.height * 0.2,
      shineWidth,
      size.height * 1.4,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(rect);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.35);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Rotating feature block — icon (with accent radial glow + pulse ring),
// title, description.
// ---------------------------------------------------------------------------

class _FeatureBlock extends StatelessWidget {
  final _OnboardingFeature feature;
  final AnimationController pulseController;
  const _FeatureBlock({
    Key? key,
    required this.feature,
    required this.pulseController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) {
            final t = pulseController.value;
            final ringScale = 1.0 + 0.08 * math.sin(t * math.pi);
            final ringAlpha = 0.18 + 0.10 * (1 - (t - 0.5).abs() * 2);
            return SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: feature.accent.withValues(alpha: ringAlpha),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          feature.accent.withValues(alpha: 0.22),
                          feature.accent.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                    child: Icon(
                      feature.icon,
                      size: 38,
                      color: feature.accent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          feature.titleKey.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          feature.descKey.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Indicators — accent-tinted active pill with soft glow.
// ---------------------------------------------------------------------------

class _Indicators extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color accent;
  final ColorScheme colorScheme;
  const _Indicators({
    required this.count,
    required this.activeIndex,
    required this.accent,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: active ? 26 : 6,
          decoration: BoxDecoration(
            color:
                active ? accent : colorScheme.onSurface.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(6),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.40),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA — solid primary fill with a pulsing primary-tinted glow shadow.
// ---------------------------------------------------------------------------

class _CtaButton extends StatelessWidget {
  final String label;
  final AnimationController pulseController;
  final VoidCallback onPressed;

  const _CtaButton({
    required this.label,
    required this.pulseController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final t = pulseController.value;
        final glowAlpha = 0.30 + 0.22 * (0.5 - (t - 0.5).abs()) * 2;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onPressed,
            child: Container(
              width: double.infinity,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: glowAlpha),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Trust signals — small icon+label chips that earn the "premium" claim with
// three concrete reassurances (encryption, offline, biometric).
// ---------------------------------------------------------------------------

class _TrustSignals extends StatelessWidget {
  const _TrustSignals();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TrustChip(
          icon: Icons.shield_rounded,
          labelKey: 'onboardingTrustEncryption',
        ),
        const SizedBox(width: 14),
        _TrustChip(
          icon: Icons.cloud_off_rounded,
          labelKey: 'onboardingTrustOffline',
        ),
        const SizedBox(width: 14),
        _TrustChip(
          icon: Icons.fingerprint_rounded,
          labelKey: 'onboardingTrustBiometric',
        ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  const _TrustChip({required this.icon, required this.labelKey});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.62,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          labelKey.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
