import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nhãn của trường nhập, tự thêm dấu * đỏ nếu là trường bắt buộc
class AppRequiredLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final TextStyle? style;

  const AppRequiredLabel({
    super.key,
    required this.text,
    this.isRequired = false,
    this.style,
  });

  static const TextStyle defaultStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: style ?? defaultStyle,
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
