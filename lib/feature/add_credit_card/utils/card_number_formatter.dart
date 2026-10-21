import 'package:flutter/services.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';

/// Groups card digits by network (Amex 4-6-5, Diners 4-6-4, others 4-4-4-4…)
/// and caps the length at what the IIN allows. Expects digits only (run
/// after [FilteringTextInputFormatter.digitsOnly]).
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue previousValue,
    TextEditingValue nextValue,
  ) {
    if (nextValue.selection.baseOffset == 0) {
      return nextValue;
    }

    final string = CardNumberLayout.format(nextValue.text);
    return nextValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(
        offset: string.length,
      ),
    );
  }
}
