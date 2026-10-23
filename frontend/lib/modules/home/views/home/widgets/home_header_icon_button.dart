import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nút tròn trắng ở đầu trang chủ (tin nhắn, thông báo)
class HomeHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Cạnh nút, mặc định bằng chiều cao ô tìm kiếm để hai bên thẳng hàng
  final double size;

  const HomeHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 48,
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
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
