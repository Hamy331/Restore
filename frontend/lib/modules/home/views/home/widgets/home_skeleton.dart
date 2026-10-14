import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Khung chờ phần nội dung trắng khi trang chủ đang tải
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block({double? width, required double height, double radius = 14}) =>
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
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const Spacer(),
                block(width: 52, height: 52, radius: 26),
              ],
            ],
          ),
          const SizedBox(height: 24),
          for (var row = 0; row < 2; row++) ...[
            Row(
              children: [
                Expanded(child: block(height: 58, radius: 16)),
                const SizedBox(width: 10),
                Expanded(child: block(height: 58, radius: 16)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          AspectRatio(aspectRatio: 2, child: block(height: 0, radius: 18)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: block(height: 240, radius: 16)),
              const SizedBox(width: 12),
              Expanded(child: block(height: 240, radius: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
