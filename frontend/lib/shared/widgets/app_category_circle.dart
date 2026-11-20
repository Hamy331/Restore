import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Khung tròn dùng chung cho icon danh mục trên mobile và desktop.
class AppCategoryCircle extends StatelessWidget {
  const AppCategoryCircle({
    super.key,
    required this.size,
    required this.fallback,
    this.background = AppColors.cream,
  });

  final double size;
  final Widget fallback;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final icon = Center(child: fallback);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: icon,
    );
  }
}
