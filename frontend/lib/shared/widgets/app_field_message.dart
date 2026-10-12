import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Dòng chữ nhỏ dưới ô nhập: ưu tiên hiển thị lỗi, nếu không thì hiển thị gợi ý
class AppFieldMessage extends StatelessWidget {
  final String? errorText;
  final String? helperText;

  const AppFieldMessage({super.key, this.errorText, this.helperText});

  @override
  Widget build(BuildContext context) {
    final text = errorText ?? helperText;
    return AnimatedSize(
      duration: AppAnimationDurations.fast,
      alignment: Alignment.topLeft,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: errorText != null
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
            ),
    );
  }
}
