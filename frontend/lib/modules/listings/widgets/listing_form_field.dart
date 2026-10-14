import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import 'required_label.dart';

/// Ô nhập có nhãn nằm bên trong khung viền (theo Figma "Hoàn thiện tin đăng")
class ListingFormField extends StatelessWidget {
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
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;

  const ListingFormField({
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
    this.inputFormatters,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final bottomText = errorText ?? helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RequiredLabel(
                text: label,
                isRequired: isRequired,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: minLines,
                maxLines: maxLines,
                keyboardType: keyboardType,
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
        if (bottomText != null) ...[
          const SizedBox(height: 6),
          Text(
            bottomText,
            style: TextStyle(
              fontSize: 12,
              color: hasError ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
