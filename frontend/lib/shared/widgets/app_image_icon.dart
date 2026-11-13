import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Icon dạng ảnh 3D (bộ AppImages.uiIcons, cùng style Hot sale).
/// Ảnh lỗi thì lùi về icon Lucide [fallback].
class AppImageIcon extends StatelessWidget {
  final String path;
  final double size;
  final IconData fallback;
  final Color fallbackColor;

  const AppImageIcon(
    this.path, {
    super.key,
    required this.size,
    required this.fallback,
    this.fallbackColor = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) => Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.contain,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
    errorBuilder: (_, _, _) =>
        Icon(fallback, size: size * 0.8, color: fallbackColor),
  );
}
