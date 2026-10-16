import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Khung chờ phần thông tin trong lúc tải chi tiết tin
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block({double? width, required double height, double radius = 8}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    Widget card(List<Widget> children) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    return Column(
      children: [
        card([
          block(width: 140, height: 26),
          const SizedBox(height: 10),
          block(height: 18),
          const SizedBox(height: 6),
          block(width: 200, height: 18),
          const SizedBox(height: 14),
          Row(
            children: [
              block(width: 72, height: 24, radius: 10),
              const SizedBox(width: 6),
              block(width: 90, height: 24, radius: 10),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        card([
          Row(
            children: [
              block(width: 52, height: 52, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(width: 120, height: 14),
                    const SizedBox(height: 8),
                    block(width: 180, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        card([
          for (var i = 0; i < 4; i++) ...[
            block(height: 12),
            const SizedBox(height: 8),
          ],
        ]),
      ],
    );
  }
}
