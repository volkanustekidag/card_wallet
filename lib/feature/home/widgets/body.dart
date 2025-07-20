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
                  SizedBox(height: 84),
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
}
