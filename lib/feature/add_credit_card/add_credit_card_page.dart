import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/add_credit_app_bar.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/credit_form.dart';
import 'package:easy_localization/easy_localization.dart';

class AddCreditCardPage extends StatefulWidget {
  final CreditCard? creditCard; // Opsiyonel parametresi

  const AddCreditCardPage({Key? key, this.creditCard}) : super(key: key);

  @override
  State<AddCreditCardPage> createState() => _AddCreditCardPageState();
}

class _AddCreditCardPageState extends State<AddCreditCardPage> {
  late final AddCreditCardController _controller =
      Get.find<AddCreditCardController>();

  @override
  void initState() {
    super.initState();
    if (widget.creditCard != null) {
      _controller.initializeForEdit(widget.creditCard!);
    } else {
      _controller.initializeForCreate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AddCreditAppBar(creditCard: widget.creditCard),
        body: SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AddCardPreview(controller: _controller),
              const SizedBox(height: 24),
              const CreditTextFieldForms(),
            ],
          ),
        )));
  }
}

class _AddCardPreview extends StatelessWidget {
  final AddCreditCardController controller;
  const _AddCardPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final card = controller.currentCard.value;
      final gradients = LinearGradients().linearGradientList;
      final gradient = gradients.isEmpty
          ? const LinearGradient(
              colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
            )
          : gradients[card.cardColorId.clamp(0, gradients.length - 1).toInt()];
      final bankName =
          card.bankName.isNotEmpty ? card.bankName : 'unknownBank'.tr();
      final cardHolder = card.cardHolder.isNotEmpty
          ? card.cardHolder
          : 'cardHolderPlaceholder'.tr();
      final expiry =
          card.expirationDate.isNotEmpty ? card.expirationDate : 'MM / YY';

      return FractionallySizedBox(
        widthFactor: 1,
        child: AspectRatio(
          aspectRatio: 1.58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0x2EFFFFFF),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Poppins', 
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _maskCardNumber(card.creditCardNumber),
                    style: TextStyle(fontFamily: 'Poppins', 
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PreviewLabelValue(
                          label: 'hName'.tr().toUpperCase(),
                          value: cardHolder,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _PreviewLabelValue(
                        label: 'valid'.tr().toUpperCase(),
                        value: expiry,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _maskCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s+'), '');
    final totalLength = 16;
    final buffer = StringBuffer();

    for (var i = 0; i < totalLength; i++) {
      final hasDigit = i < digits.length;
      final shouldReveal =
          digits.length >= 4 && i >= digits.length - 4 && hasDigit;
      buffer.write(shouldReveal ? digits[i] : '•');
      final isGroupBoundary = (i + 1) % 4 == 0 && i != totalLength - 1;
      if (isGroupBoundary) buffer.write(' ');
    }
    return buffer.toString();
  }
}

class _PreviewLabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewLabelValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins', 
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'Poppins', 
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
