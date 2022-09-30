import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:easy_localization/easy_localization.dart';

Future<dynamic> showPrivacyPolicyBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    elevation: 0,
    backgroundColor: Color.fromRGBO(0, 0, 0, 0),
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return PrivacyPolicyBottomSheetBody();
    },
  );
}

class PrivacyPolicyBottomSheetBody extends StatefulWidget {
  const PrivacyPolicyBottomSheetBody({super.key});

  @override
  State<PrivacyPolicyBottomSheetBody> createState() =>
      _PrivacyPolicyBottomSheetBodyState();
}

class _PrivacyPolicyBottomSheetBodyState
    extends State<PrivacyPolicyBottomSheetBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: PaddingConstants.high(),
            child: Text(
              "PPT".tr(),
            ),
          ),
        ),
      ),
    );
  }
}
