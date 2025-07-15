import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TextFieldCard extends StatelessWidget {
  final maxLength;
  final inputFormatters;
  final onChanged;
  final textInputType;
  final iconData;
  final hintText;
  final label;

  const TextFieldCard({
    Key? key,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.textInputType,
    this.iconData,
    this.hintText,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90.w,
      child: TextField(
        maxLength: maxLength,
        keyboardType: textInputType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
            iconColor: Colors.white,
            prefixIcon: Icon(
              iconData,
              color: Colors.white,
            ),
            labelStyle: TextStyle(fontSize: 10.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            helperStyle: TextStyle(color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
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
