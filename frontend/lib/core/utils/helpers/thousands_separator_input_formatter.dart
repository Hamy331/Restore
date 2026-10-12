import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Chỉ cho nhập số và tự thêm dấu phân cách hàng nghìn (VD: 15.000.000)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter({String? locale})
    : _format = NumberFormat.decimalPattern(locale);

  final NumberFormat _format;

  static const int maxDigits = 12;

  /// Đọc lại giá trị số từ chuỗi đã định dạng
  static int? parse(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;
    final value = parse(digits);
    if (value == null) return const TextEditingValue();
    final formatted = _format.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
