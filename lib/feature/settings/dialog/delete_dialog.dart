import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/data/local_services/card_services/iban_card_service.dart';

Future<void> showDialogDeleteData(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) {
      return DeleteDialodBody();
    },
  );
}

class DeleteDialodBody extends StatelessWidget {
  const DeleteDialodBody({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 40.h,
        width: 80.w,
        decoration: BoxDecoration(
            color: ColorConstants.secondaryColor,
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.info,
              color: Colors.white,
              size: 18.w,
            ),
            Padding(
              padding: PaddingConstants.normal(),
              child: DefaultTextStyle(
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400),
                child: Text(
                  "areUSure".tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: PaddingConstants.normal(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text("cancel".tr()),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await CreditCardService().deleteAllData();

                      await IbanCardService().deleteAllData();

                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("delete".tr()),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
