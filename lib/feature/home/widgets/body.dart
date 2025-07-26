import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/core/widgets/background_shapes_painter.dart';
import 'package:wallet_app/feature/home/widgets/cards_list_view.dart';
import 'package:wallet_app/feature/home/widgets/dashed_empty_card.dart';
import 'package:wallet_app/feature/home/widgets/row_titles.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeBody extends StatelessWidget {
  final HomeController controller;

  const HomeBody({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => SafeArea(
          child: Stack(
            children: [
              // Background Shapes
              Positioned.fill(
                child: CustomPaint(
                  painter: BackgroundShapesPainter(),
                ),
              ),
              ListView(
                children: [
                  AppBar(
                    elevation: 0,
                    centerTitle: true,
                    forceMaterialTransparency: true,
                    leading: IconButton(
                      icon: Icon(Icons.menu_rounded, size: 20.sp),
                      onPressed: () {
                        Get.toNamed('/settings')?.then(
                          (value) => Get.find<HomeController>().refreshData(),
                        );
                      },
                    ),
                    title: Text(
                      "CARDWALLET",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        letterSpacing: 0.005,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Quick Add Shortcuts
                  _buildQuickAddShortcuts(context),
                  SizedBox(height: 40),

                  // Credit Cards Section
                  Column(
                    children: [
                      const RowTitles(
                        title: "yourCC",
                        route: "/creditCards",
                        iconPath: "assets/svg/ccard.svg",
                      ),
                      SizedBox(height: 16),
                      controller.creditCards.isEmpty
                          ? DashedEmptyCard(
                              text: "addFirstCC".tr(),
                              route: "/addCreditCard",
                            )
                          : CardsListView(
                              list: controller.creditCards,
                              cardType: 0,
                            ),
                    ],
                  ),
                  SizedBox(height: 40),
                  // IBAN Cards Section
                  Column(
                    children: [
                      const RowTitles(
                          title: "yourIC",
                          route: "/ibanCards",
                          iconPath: "assets/svg/bank.svg"),
                      SizedBox(height: 16),
                      controller.ibanCards.isEmpty
                          ? DashedEmptyCard(
                              text: "addFirstIC".tr(),
                              route: "/addIbanCard",
                            )
                          : CardsListView(
                              list: controller.ibanCards,
                              cardType: 1,
                            ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildQuickAddShortcuts(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickAddCard(
              context,
              title: "addCC".tr(),
              subtitle: "addCreditCard".tr(),
              icon: Icons.credit_card,
              color: Colors.blue,
              route: "/addCreditCard",
              gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildQuickAddCard(
              context,
              title: "addIC".tr(),
              subtitle: "addIbanCard".tr(),
              icon: Icons.account_balance,
              color: Colors.green,
              route: "/addIbanCard",
              gradientColors: [Colors.green.shade400, Colors.green.shade600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(route)?.then(
              (value) => Get.find<HomeController>().refreshData(),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 124,
            child: Stack(
              children: [
                // Background "+" icon at top right
                Positioned(
                  top: -32,
                  right: -32,
                  child: Icon(
                    Icons.add,
                    size: 124,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                // Main content
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon with circular background
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
