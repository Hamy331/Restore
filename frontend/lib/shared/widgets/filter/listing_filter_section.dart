import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Một nhóm tiêu chí trong sheet Bộ lọc: tiêu chí in đậm, nội dung bên dưới
class ListingFilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const ListingFilterSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Các chip lựa chọn xuống dòng tự động trong một nhóm tiêu chí
class ListingFilterChipWrap extends StatelessWidget {
  final List<Widget> children;

  const ListingFilterChipWrap({super.key, required this.children});

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
}
