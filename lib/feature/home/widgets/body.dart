import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/widgets/background_shapes_painter.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_shelves_sliver.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_hero_sliver.dart';
import 'package:wallet_app/feature/home/widgets/sections/premium_status_strip.dart';
import 'package:wallet_app/feature/home/widgets/sections/quick_action_rail.dart';
import 'package:wallet_app/feature/home/widgets/sections/smart_suggestion_card.dart';
import 'package:wallet_app/feature/home/widgets/sections/welcome_stack.dart';

/// Home page body, redesigned around a CustomScrollView with a sliver
/// hero header. Each chunk lives in its own widget under
/// `widgets/sections/` so this file stays an orchestrator (~120 lines)
/// instead of the previous 871-line monolith.
class HomeBody extends StatelessWidget {
  final HomeController controller;

  const HomeBody({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _HomeBackdrop()),
        Obx(() {
          final hasAnyCard = controller.creditCards.isNotEmpty ||
              controller.ibanCards.isNotEmpty ||
              controller.loyaltyCards.isNotEmpty;

          // Local-only app — no remote refresh needed, so we drop the
          // RefreshIndicator. Reactive state already rebuilds when data
          // changes.
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              HomeHeroSliver(controller: controller),
              SliverToBoxAdapter(
                child: PremiumStatusStrip(controller: controller),
              ),
              if (!hasAnyCard) ...[
                const SliverToBoxAdapter(child: WelcomeStack()),
                SliverToBoxAdapter(
                  child: QuickActionRail(controller: controller),
                ),
              ] else ...[
                SliverToBoxAdapter(
                  child: QuickActionRail(controller: controller),
                ),
                CardShelvesSliver(controller: controller),
                SliverToBoxAdapter(
                  child: SmartSuggestionCard(controller: controller),
                ),
              ],
              const SliverPadding(
                padding: EdgeInsets.only(bottom: kSpaceXXL),
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// Decorative gradient blobs that sit behind the hero only — the
/// previous full-screen 5%-opacity painter was barely visible.
class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: isDark ? 0.18 : 0.12,
      child: CustomPaint(painter: BackgroundShapesPainter()),
    );
  }
}
