import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';

class ColorsListView extends StatelessWidget {
  const ColorsListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddCreditCardController>();
    final premium = Get.find<PremiumController>();
    final gradients = LinearGradients().linearGradientList;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final selectedId = controller.currentCard.value.cardColorId;
      final isPremium = premium.isPremium;

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(gradients.length, (index) {
          final isSelected = index == selectedId;
          final locked = !isPremium && GradientCatalogue.isPremium(index);
          return GestureDetector(
            onTap: () {
              if (locked) {
                Get.toNamed('/premium');
                return;
              }
              controller.updateCardField('cardColorId', index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradients[index],
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : const Color(0x66FFFFFF),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: locked
                  ? const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : (isSelected
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 18)
                      : null),
            ),
          );
        }),
      );
    });
  }
}
