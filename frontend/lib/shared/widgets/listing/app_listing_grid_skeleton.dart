import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Khung chờ lưới thẻ tin 2 cột khi đang tải trang đầu
class AppListingGridSkeleton extends StatelessWidget {
  final int rows;

  const AppListingGridSkeleton({super.key, this.rows = 2});

  @override
  Widget build(BuildContext context) {
    Widget block() => Expanded(
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var row = 0; row < rows; row++) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(children: [block(), const SizedBox(width: 12), block()]),
          ],
        ],
      ),
    );
  }
}
