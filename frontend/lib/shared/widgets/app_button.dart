import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );
    final callback = isLoading ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: switch (variant) {
        AppButtonVariant.primary => ElevatedButton(
          onPressed: callback,
          child: child,
        ),
        AppButtonVariant.secondary => OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: child,
        ),
        AppButtonVariant.text => TextButton(onPressed: callback, child: child),
      },
    );
  }
}
