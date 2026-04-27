import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/router/getx_routes.dart';

/// One-time intro shown before the auth screen on first launch. Tracking
/// uses a single `onboarding_seen` flag in secure storage so a re-install
/// brings it back.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  static const String storageKey = 'onboarding_seen';

  static Future<bool> shouldShow() async {
    try {
      const storage = FlutterSecureStorage();
      final value = await storage.read(key: storageKey);
      return value != 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markSeen() async {
    try {
      await const FlutterSecureStorage().write(
        key: storageKey,
        value: 'true',
      );
    } catch (_) {
      // best-effort
    }
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentIndex = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.style_rounded,
      titleKey: 'onboardingSlide1Title',
      descKey: 'onboardingSlide1Desc',
      iconColor: Color(0xFF4568DC),
    ),
    _OnboardingSlide(
      icon: Icons.lock_rounded,
      titleKey: 'onboardingSlide2Title',
      descKey: 'onboardingSlide2Desc',
      iconColor: Color(0xFF11998E),
    ),
    _OnboardingSlide(
      icon: Icons.fingerprint_rounded,
      titleKey: 'onboardingSlide3Title',
      descKey: 'onboardingSlide3Desc',
      iconColor: Color(0xFFFF6A00),
    ),
    _OnboardingSlide(
      icon: Icons.workspace_premium_rounded,
      titleKey: 'onboardingSlide4Title',
      descKey: 'onboardingSlide4Desc',
      iconColor: Color(0xFFD4AF37),
    ),
  ];

  bool get _isLast => _currentIndex == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPage._markSeen();
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.auth);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'onboardingSkip'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) =>
                    _SlideView(slide: _slides[index]),
              ),
            ),
            const SizedBox(height: 12),
            _buildIndicators(colorScheme),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isLast
                        ? 'onboardingGetStarted'.tr()
                        : 'onboardingNext'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final active = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: active ? 22 : 6,
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final Color iconColor;
  const _OnboardingSlide({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.iconColor,
  });
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(slide.icon, size: 72, color: slide.iconColor),
          ),
          const SizedBox(height: 36),
          Text(
            slide.titleKey.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.descKey.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
