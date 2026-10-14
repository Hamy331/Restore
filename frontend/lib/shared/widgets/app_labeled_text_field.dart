import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'app_field_message.dart';
import 'app_required_label.dart';

/// Ô nhập kính mờ có nhãn nằm bên trong khung (theo Figma đăng tin)
class AppLabeledTextField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;

  const AppLabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.onChanged,
    this.hintText,
    this.helperText,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.suffix,
  });

  static const double borderRadius = AppGlass.fieldRadius;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          decoration: BoxDecoration(
            color: AppGlass.fillStrong,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: hasError ? AppColors.error : AppGlass.stroke,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRequiredLabel(
                text: label,
                isRequired: isRequired,
                style: AppRequiredLabel.captionStyle,
              ),
              TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: minLines,
                maxLines: maxLines,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                inputFormatters: [
                  if (maxLength != null)
                    LengthLimitingTextInputFormatter(maxLength),
                  ...?inputFormatters,
                ],
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  suffixIcon: suffix,
                  suffixIconConstraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
        AppFieldMessage(errorText: errorText, helperText: helperText),
      ],
    );
  }
}
