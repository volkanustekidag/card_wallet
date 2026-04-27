import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

Future<dynamic> showPrivacyPolicyBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    elevation: 0,
    backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return const PrivacyPolicyBottomSheetBody();
    },
  );
}

class PrivacyPolicyBottomSheetBody extends StatelessWidget {
  const PrivacyPolicyBottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.7,
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text("PPT".tr()),
          ),
        ),
      ),
    );
  }
}
