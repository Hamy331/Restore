import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nút icon tròn ở hàng đầu trang chủ (Tin đã lưu, Thông báo)
class HomeHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Cạnh vùng bấm
  final double size;

  const HomeHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 24, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
