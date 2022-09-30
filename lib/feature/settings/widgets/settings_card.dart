import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class SettingsCard extends StatelessWidget {
  final iconData;
  final title;
  final trailing;
  final onTap;
  const SettingsCard({
    this.iconData,
    this.title,
    this.trailing,
    this.onTap,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: ColorConstants.secondaryColor,
        child: ListTile(
          leading: Icon(
            iconData,
            color: Colors.white,
          ),
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w400),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}
