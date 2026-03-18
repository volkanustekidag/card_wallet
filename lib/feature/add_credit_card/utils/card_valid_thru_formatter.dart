import 'package:flutter/services.dart';

class CardValidThruFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    var buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if (i == 1 && digitsOnly.length > 2) {
        buffer.write(' / ');
      }
    }

    var formatted = buffer.toString();
    if (digitsOnly.length > 2 && !formatted.contains(' / ')) {
      formatted =
          '${digitsOnly.substring(0, 2)} / ${digitsOnly.substring(2)}';
    } else if (digitsOnly.length > 2) {
      formatted =
          '${digitsOnly.substring(0, 2)} / ${digitsOnly.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
