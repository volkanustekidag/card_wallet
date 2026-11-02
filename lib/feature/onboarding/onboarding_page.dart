import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:hive/hive.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';
import 'package:wallet_app/feature/scanner/add_flows.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/ui/card/card_face.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// First launch, four steps on one stage (in the app's theme): welcome → what do you
/// carry → add the first card → lock & reminders. Every step can be left
/// and finished later; nothing here is required to use the app.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  static const String storageKey = 'onboarding_seen';
  static const String _boxName = 'app_state';

  // Earlier builds wrote the flag to FlutterSecureStorage (iOS Keychain
  // survives uninstall). The flag lives in Hive now; the stale Keychain
  // entry is cleaned up once.
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

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _step = 0;
  final Set<String> _carry = {'loyalty'};
  int _cardsAdded = 0;
  late final bool _hadPin;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _hadPin = AuthenticationService().hasPasswordSync();
    // The lock step below covers the PIN; don't let a first card save
    // also pop the post-add PIN nudge on top of onboarding.
    SessionPromptGate.markUsed();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int step) {
    HapticFeedback.selectionClick();
    setState(() => _step = step);
    _pages.animateToPage(step,
        duration: CwMotion.slow, curve: CwMotion.standard);
  }

  Future<int> _cardCount() async {
    try {
      final r = await Future.wait([
        CreditCardService().getAllCreditCards(),
        IbanCardService().getAllIbanCards(),
        LoyaltyCardService().getAllLoyaltyCards(),
      ]);
      return r.fold<int>(0, (n, l) => n + (l as List).length);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _afterAdd(Future<void> Function() flow) async {
    final before = await _cardCount();
    await flow();
    final after = await _cardCount();
    if (!mounted) return;
    if (after > before) {
      setState(() => _cardsAdded += after - before);
      _go(3);
    }
  }

  ScanMode get _preferredMode {
    if (_carry.length == 1) {
      switch (_carry.first) {
        case 'cards':
          return ScanMode.card;
        case 'iban':
          return ScanMode.iban;
        case 'loyalty':
        case 'members':
          return ScanMode.barcode;
      }
    }
    return ScanMode.auto;
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    unawaited(OnboardingPage._markSeen());
    unawaited(AnalyticsService.instance.logOnboardingComplete());
    if (_cardsAdded == 0) {
      unawaited(
          AnalyticsService.instance.logEvent('first_card_picker_skipped'));
    }
    if (!mounted) return;
    // Users who already had a PIN (migrated) still see the lock screen.
    Get.offAllNamed(_hadPin ? AppRoutes.auth : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: cwOverlayStyle(context),
      child: Theme(
        data: Theme.of(context),
        child: PopScope(
          canPop: _step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _step > 0) _go(_step - 1);
          },
          child: Scaffold(
            backgroundColor: c.bg,
            body: Stack(
              children: [
                const Positioned.fill(child: _Stage()),
                SafeArea(
                  child: Column(
                    children: [
                      AnimatedOpacity(
                        duration: CwMotion.base,
                        opacity: _step == 0 ? 0 : 1,
                        child: _Progress(step: _step),
                      ),
                      Expanded(
                        child: PageView(
                          controller: _pages,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _Welcome(onNext: () => _go(1)),
                            _Carry(
                              selected: _carry,
                              onToggle: (k) => setState(() => _carry.contains(k)
                                  ? _carry.remove(k)
                                  : _carry.add(k)),
                              onImport: () =>
                                  _afterAdd(() => openImport(context)),
                              onNext: () {
                                UiPrefs.instance.setCarry(_carry.toList());
                                _go(2);
                              },
                            ),
                            _FirstCard(
                              added: _cardsAdded,
                              onScan: () => _afterAdd(
                                  () => openScanner(mode: _preferredMode)),
                              onImport: () =>
                                  _afterAdd(() => openImport(context)),
                              onType: () =>
                                  _afterAdd(() => pickManualEntry(context)),
                              onLater: () => _go(3),
                            ),
                            _LockStep(
                              hadPin: _hadPin,
                              onDone: _finish,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage();

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.0,
          colors: [
            Color.alphaBlend(
                c.ink.withValues(alpha: dark ? 0.07 : 0.035), c.bg),
            c.bg,
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int step;
  const _Progress({required this.step});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
        child: Row(
          children: [
            for (var i = 1; i <= 3; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: CwMotion.base,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? CwColors.of(context).ink
                        : CwColors.of(context).ink.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Bottom-pinned primary button for every step.
class _Primary extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _Primary({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          disabledBackgroundColor: c.ink.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CwRadius.l)),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: CwType.headline
                .copyWith(color: c.bg, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final VoidCallback onNext;
  const _Welcome({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final w = MediaQuery.sizeOf(context).width * 0.66;
    Widget demo(int material, double angle, Offset at, Widget child) =>
        Transform.translate(
          offset: at,
          child: Transform.rotate(
            angle: angle,
            child: CardFace(
              material: CardMaterial.of(material),
              width: w,
              height: w / 1.586,
              child: child,
            ),
          ),
        );
    Widget label(String t) => Align(
          alignment: Alignment.topLeft,
          child: Text(t,
              style: CwType.overline
                  .copyWith(color: Colors.white.withValues(alpha: 0.75))),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                height: w / 1.586 + 120,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    demo(10, -0.12, const Offset(-26, -56),
                        label('cwTypeLoyalty'.tr().toUpperCase())),
                    demo(2, 0.08, const Offset(30, -8), label('IBAN')),
                    demo(
                      11,
                      -0.03,
                      const Offset(-6, 52),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('cwTypeCard'.tr().toUpperCase()),
                          const Spacer(),
                          Text('••••  ••••  ••••  4242',
                              style:
                                  CwType.mono(size: 15, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text('cwObTitle'.tr(),
              style: CwType.display.copyWith(color: c.ink, fontSize: 32)),
          const SizedBox(height: 12),
          Text('cwObBody'.tr(),
              style: CwType.body.copyWith(color: c.ink2, height: 1.45)),
          const SizedBox(height: 28),
          _Primary(label: 'cwGetStarted'.tr(), onPressed: onNext),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            runAlignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              _TrustItem(CwIcons.lock, 'cwTrustOnDevice'.tr()),
              _TrustItem(CwIcons.offline, 'cwTrustOffline'.tr()),
              _TrustItem(CwIcons.user, 'cwTrustNoSignup'.tr()),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final CwIcons icon;
  final String text;
  const _TrustItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CwIcon(icon, size: 13, color: c.mute),
        const SizedBox(width: 5),
        Text(text, style: CwType.caption.copyWith(color: c.mute)),
      ],
    );
  }
}

class _Carry extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onImport;
  final VoidCallback onNext;

  const _Carry({
    required this.selected,
    required this.onToggle,
    required this.onImport,
    required this.onNext,
  });

  static const _options = [
    ('loyalty', CwIcons.tag, 'cwCarryLoyalty', 'cwCarryLoyaltySub'),
    ('cards', CwIcons.card, 'cwCarryCards', 'cwCarryCardsSub'),
    ('iban', CwIcons.bank, 'cwCarryIban', 'cwCarryIbanSub'),
    ('members', CwIcons.plane, 'cwCarryMembers', 'cwCarryMembersSub'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('cwCarryTitle'.tr(),
              style: CwType.display.copyWith(color: c.ink, fontSize: 30)),
          const SizedBox(height: 6),
          Text('cwCarrySub'.tr(),
              style: CwType.callout.copyWith(color: c.ink2)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var r = 0; r < 2; r++) ...[
                    if (r > 0) const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = r * 2; i < r * 2 + 2; i++) ...[
                            if (i.isOdd) const SizedBox(width: 10),
                            Expanded(
                              child: _CarryTile(
                                icon: _options[i].$2,
                                title: _options[i].$3.tr(),
                                sub: _options[i].$4.tr(),
                                on: selected.contains(_options[i].$1),
                                onTap: () => onToggle(_options[i].$1),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Material(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(CwRadius.m),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(CwRadius.m),
                      onTap: onImport,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CwIcon(CwIcons.import,
                                size: CwIconSize.m, color: c.ink),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('cwCarryImport'.tr(),
                                      style: CwType.callout.copyWith(
                                          color: c.ink,
                                          fontWeight: FontWeight.w700)),
                                  Text('cwCarryImportSub'.tr(),
                                      style: CwType.footnote
                                          .copyWith(color: c.ink2)),
                                ],
                              ),
                            ),
                            CwIcon(CwIcons.chevronRight,
                                size: 18, color: c.ink2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Primary(
            label: 'cwContinue'.tr(),
            onPressed: selected.isEmpty ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _CarryTile extends StatelessWidget {
  final CwIcons icon;
  final String title;
  final String sub;
  final bool on;
  final VoidCallback onTap;

  const _CarryTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: CwMotion.fast,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: on
                ? c.ink.withValues(alpha: 0.10)
                : c.ink.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(CwRadius.l),
            border: Border.all(
              color: on ? c.ink : c.ink.withValues(alpha: 0.12),
              width: on ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CwIcon(icon, size: CwIconSize.l, color: c.ink),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: CwMotion.fast,
                    opacity: on ? 1 : 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration:
                          BoxDecoration(color: c.ink, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: CwIcon(CwIcons.check, size: 14, color: c.bg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(title, style: CwType.headline.copyWith(color: c.ink)),
              const SizedBox(height: 2),
              Text(sub, style: CwType.footnote.copyWith(color: c.mute)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirstCard extends StatelessWidget {
  final int added;
  final VoidCallback onScan;
  final VoidCallback onImport;
  final VoidCallback onType;
  final VoidCallback onLater;

  const _FirstCard({
    required this.added,
    required this.onScan,
    required this.onImport,
    required this.onType,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    Widget secondary(CwIcons icon, String label, VoidCallback onTap) =>
        Expanded(
          child: Material(
            color: c.ink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(CwRadius.m),
            child: InkWell(
              borderRadius: BorderRadius.circular(CwRadius.m),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CwIcon(icon, size: 18, color: c.ink),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: CwType.callout.copyWith(
                              color: c.ink, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('cwFirstTitle'.tr(),
              style: CwType.display.copyWith(color: c.ink, fontSize: 30)),
          const SizedBox(height: 6),
          Text('cwFirstSub'.tr(),
              style: CwType.callout.copyWith(color: c.ink2)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onScan,
            child: AspectRatio(
              aspectRatio: 1.45,
              child: Container(
                decoration: BoxDecoration(
                  color: c.ink.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(CwRadius.xl),
                ),
                padding: const EdgeInsets.all(22),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFF34D399), width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CwIcon(CwIcons.scan, size: 40, color: c.ink),
                      const SizedBox(height: 12),
                      Text('cwOpenCamera'.tr(),
                          style: CwType.headline.copyWith(color: c.ink)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              secondary(CwIcons.import, 'cwImportCards'.tr(), onImport),
              const SizedBox(width: 10),
              secondary(CwIcons.keyboard, 'cwTypeItIn'.tr(), onType),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onLater,
            child: Text('cwLater'.tr(),
                style: CwType.callout
                    .copyWith(color: c.mute, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _LockStep extends StatefulWidget {
  final bool hadPin;
  final VoidCallback onDone;
  const _LockStep({required this.hadPin, required this.onDone});

  @override
  State<_LockStep> createState() => _LockStepState();
}

class _LockStepState extends State<_LockStep> {
  bool _reminders = false;

  AuthController get _auth => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _reminders = UiPrefs.instance.remindByDefault.value;
  }

  Future<void> _toggleLock(bool on) async {
    final auth = _auth;
    if (on && !auth.hasPassword.value) {
      final created = await Get.to<bool>(
        () => const PinActionPage(),
        arguments: PinAction.create,
      );
      if (created == true && auth.isBiometricAvailable.value) {
        await auth.toggleBiometric(true);
      }
    } else if (!on && auth.hasPassword.value) {
      final verified = await Get.to<bool>(
        () => const PinActionPage(),
        arguments: PinAction.verify,
      );
      if (verified == true) await auth.removePassword();
    }
    if (mounted) setState(() {});
  }

  /// On: expiry reminders for the cards added so far and every new one
  /// (asks for the notification permission first). Off: undoes that.
  Future<void> _toggleReminders(bool on) async {
    if (on && !await CardReminderService().requestPermission()) return;
    if (mounted) setState(() => _reminders = on);
    await UiPrefs.instance.setRemindByDefault(on);
    try {
      final service = CreditCardService();
      for (final card in await service.getAllCreditCards()) {
        if (card.expiryReminderEnabled == on) continue;
        card.expiryReminderEnabled = on;
        await card.save();
        await CardReminderService.guarded(
          'onboarding.reminders',
          () => CardReminderService().scheduleForCard(card),
        );
      }
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'onboarding.reminders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final auth = _auth;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: c.ink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: CwIcon(CwIcons.shield, size: 40, color: c.ink),
            ),
          ),
          const SizedBox(height: 22),
          Text('cwLockTitle'.tr(),
              textAlign: TextAlign.center,
              style: CwType.display.copyWith(color: c.ink, fontSize: 28)),
          const SizedBox(height: 10),
          Text('cwLockSub'.tr(),
              textAlign: TextAlign.center,
              style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
          const SizedBox(height: 24),
          Obx(() {
            final hasPin = auth.hasPassword.value;
            final bio = auth.isBiometricAvailable.value;
            return Container(
              decoration: BoxDecoration(
                color: c.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(CwRadius.l),
              ),
              child: Column(
                children: [
                  _NightRow(
                    icon: bio ? CwIcons.faceId : CwIcons.lock,
                    title: bio
                        ? '${'cwLockWithPin'.tr()} · ${auth.getBiometricDisplayName()}'
                        : 'cwLockWithPin'.tr(),
                    sub: 'cwLockWithPinSub'.tr(),
                    trailing: CwSwitch(value: hasPin, onChanged: _toggleLock),
                  ),
                  Divider(
                      height: 1,
                      indent: 60,
                      color: c.ink.withValues(alpha: 0.08)),
                  _NightRow(
                    icon: CwIcons.bell,
                    title: 'cwRemindExpire'.tr(),
                    sub: 'cwRemindExpireSub'.tr(),
                    trailing: CwSwitch(
                        value: _reminders, onChanged: _toggleReminders),
                  ),
                ],
              ),
            );
          }),
          const Spacer(flex: 2),
          _Primary(label: 'cwDoneOpen'.tr(), onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _NightRow extends StatelessWidget {
  final CwIcons icon;
  final String title;
  final String sub;
  final Widget trailing;

  const _NightRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    // Like CwRow: tapping anywhere on a switch row flips the switch.
    final t = trailing;
    final onTap = t is CwSwitch && t.onChanged != null
        ? () => t.onChanged!(!t.value)
        : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CwRadius.l),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.ink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: CwIcon(icon, size: 18, color: c.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: CwType.callout
                          .copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                  Text(sub, style: CwType.footnote.copyWith(color: c.mute)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
