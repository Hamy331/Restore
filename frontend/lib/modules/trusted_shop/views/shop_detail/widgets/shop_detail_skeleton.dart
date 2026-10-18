import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Khung chờ hồ sơ shop khi mở bằng đường dẫn (chưa có thông tin shop)
class ShopDetailProfileSkeleton extends StatelessWidget {
  const ShopDetailProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block({double? width, required double height, double radius = 8}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(width: double.infinity, height: 158, radius: 22),
          const SizedBox(height: 12),
          block(width: 200, height: 22),
          const SizedBox(height: 10),
          block(width: 140, height: 16),
          const SizedBox(height: 16),
          block(width: double.infinity, height: 64, radius: 18),
          const SizedBox(height: 12),
          block(width: double.infinity, height: 62, radius: 18),
        ],
      ),
    );
  }
}
