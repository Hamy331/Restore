import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Bộ nút hành động dùng chung (thanh cuối trang, nút trong sheet) để mọi
/// nút cùng chiều cao, bo góc, cỡ chữ và một tông cam:
/// - [AppPrimaryActionButton]: nền gradient cam, hành động chính.
/// - [AppSecondaryActionButton]: nền cam nhạt viền cam, hành động phụ;
///   bỏ [AppSecondaryActionButton.label] để thành nút vuông chỉ có icon.
class AppActionButtonStyle {
  AppActionButtonStyle._();

  static const double height = 52;
  static final BorderRadius radius = BorderRadius.circular(16);
  static const TextStyle labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, Color(0xFFF2B54A)],
  );
}

class AppPrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppPrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final radius = AppActionButtonStyle.radius;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: AppActionButtonStyle.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: enabled || isLoading
            ? AppActionButtonStyle.primaryGradient
            : null,
        color: enabled || isLoading ? null : AppColors.border,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: Center(
            child: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  )
                : _ButtonContent(
                    label: label,
                    icon: icon,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}

class AppSecondaryActionButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Chú thích khi chỉ có icon (đọc màn hình, nhấn giữ)
  final String? tooltip;

  const AppSecondaryActionButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppActionButtonStyle.radius;
    final enabled = onPressed != null;
    final iconOnly = label == null;
    Widget button = Material(
      color: AppColors.primarySoft.withValues(alpha: enabled ? 1 : 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: enabled ? 0.45 : 0.2),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: SizedBox(
          width: iconOnly ? AppActionButtonStyle.height : null,
          height: AppActionButtonStyle.height,
          child: Center(
            child: iconOnly
                ? Icon(icon, size: 22, color: AppColors.primaryDark)
                : _ButtonContent(
                    label: label!,
                    icon: icon,
                    color: AppColors.primaryDark,
                  ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Icon nhỏ + chữ, tự thu nhỏ khi nút hẹp
class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              maxLines: 1,
              style: AppActionButtonStyle.labelStyle.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
