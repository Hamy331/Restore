import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Nhãn của trường nhập, thêm dấu * đỏ nếu bắt buộc
class RequiredLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final TextStyle? style;

  const RequiredLabel({
    super.key,
    required this.text,
    this.isRequired = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        style ??
        const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );
    return Text.rich(
      TextSpan(
        text: text,
        style: baseStyle,
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}
