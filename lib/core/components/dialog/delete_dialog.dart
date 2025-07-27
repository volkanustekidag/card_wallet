import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    Key? key,
    this.onConfirm,
    this.title = "areUSure",
    this.cancelText = "cancel",
  }) : super(key: key);

  final Function? onConfirm;
  final String title;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            if (onConfirm != null) {
              onConfirm!();
            }
            Navigator.pop(context);
          },
          child: Text('yes'.tr()),
        ),
      ],
    );
  }
}
