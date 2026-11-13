import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Một khối của trang Quản lý shop: thẻ nền kem, tiêu đề đậm, mô tả nhỏ (tuỳ
/// chọn) rồi nội dung
class MyShopSection extends StatelessWidget {
  const MyShopSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
