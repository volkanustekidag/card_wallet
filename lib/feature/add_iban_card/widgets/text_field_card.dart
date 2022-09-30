import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TextFieldCard extends StatelessWidget {
  final onChanged;
  final iconData;
  final label;
  final hintText;

  const TextFieldCard({
    Key? key,
    this.onChanged,
    this.iconData,
    this.label,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85.w,
      child: TextField(
        maxLength: 16,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            focusColor: Colors.white,
            iconColor: Colors.white,
            prefixIcon: Icon(
              iconData,
              color: Colors.white,
            ),
            labelStyle: TextStyle(fontSize: 10.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            helperStyle: TextStyle(color: Colors.white),
            hintStyle: const TextStyle(color: Colors.white),
            label: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
            hintText: hintText),
      ),
    );
  }
}
