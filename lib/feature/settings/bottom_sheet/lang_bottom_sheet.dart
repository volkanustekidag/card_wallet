import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:easy_localization/easy_localization.dart';

Future<dynamic> showLangChoseeBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    elevation: 0,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return LanguageBottomSheetBody();
    },
  );
}

class LanguageBottomSheetBody extends StatelessWidget {
  const LanguageBottomSheetBody({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25.h,
      decoration: const BoxDecoration(
        color: ColorConstants.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: CupertinoPicker(
        magnification: 1.22,
        squeeze: 1.2,
        useMagnifier: true,
        itemExtent: 6.w,
        onSelectedItemChanged: (value) => value == 1
            ? context.setLocale(
                const Locale("tr", "TR"),
              )
            : context.setLocale(
                const Locale("en", "US"),
              ),
        children: [
          Text(
            "selecetLang".tr(),
            style: const TextStyle(color: Colors.white),
          ),
          const Text(
            "TR",
            style: TextStyle(color: Colors.white),
          ),
          const Text(
            "ENG",
            style: TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }
}
