import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'app_field_message.dart';
import 'app_labeled_text_field.dart';
import 'app_required_label.dart';

/// Ô chọn kính mờ dạng dropdown có nhãn bên trong khung (VD: Địa chỉ)
class AppSelectField extends StatelessWidget {
  final String label;
  final String? value;
  final String? placeholder;
  final bool isRequired;
  final String? errorText;
  final String? helperText;
  final IconData? leadingIcon;
  final bool enabled;
  final VoidCallback onTap;

  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.isRequired = false,
    this.errorText,
    this.helperText,
    this.leadingIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final radius = BorderRadius.circular(AppLabeledTextField.borderRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: enabled ? AppGlass.fillStrong : AppGlass.fillSoft,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: errorText != null ? AppColors.error : AppGlass.stroke,
                ),
              ),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 22, color: AppColors.primaryDark),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppRequiredLabel(
                          text: label,
                          isRequired: isRequired,
                          style: AppRequiredLabel.captionStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasValue ? value! : (placeholder ?? ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: hasValue
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    AppIcons.chevronDown,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        AppFieldMessage(errorText: errorText, helperText: helperText),
      ],
    );
  }
}
