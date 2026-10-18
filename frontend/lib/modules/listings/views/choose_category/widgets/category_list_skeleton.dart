import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Khung xương nhấp nháy nhẹ trong lúc tải danh mục
class CategoryListSkeleton extends StatefulWidget {
  final int itemCount;

  const CategoryListSkeleton({super.key, this.itemCount = 6});

  @override
  State<CategoryListSkeleton> createState() => _CategoryListSkeletonState();
}

class _CategoryListSkeletonState extends State<CategoryListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Column(
        children: [
          for (var i = 0; i < widget.itemCount; i++) const _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final block = AppColors.primarySoft.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.45,
                  child: Container(height: 16, color: block),
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Container(height: 12, color: block),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
