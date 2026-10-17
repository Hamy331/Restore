import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Khung chờ lưới tin khi đang lấy vị trí hoặc tải trang đầu
class NearbySkeleton extends StatelessWidget {
  const NearbySkeleton({super.key});

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
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(children: [block(), const SizedBox(width: 12), block()]),
          ],
        ],
      ),
    );
  }
}
