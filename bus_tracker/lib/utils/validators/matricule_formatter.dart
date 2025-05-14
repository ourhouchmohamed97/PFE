import 'package:flutter/services.dart';
class MatriculeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll('|', '');

    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 3) {
        formatted += '|';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}