import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nút tròn trắng viền mảnh đặt trên nền cam kem của đầu trang
/// (quay lại, định vị...), cùng kiểu nút ở đầu trang chủ.
class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color iconColor;
  final double size;

  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
