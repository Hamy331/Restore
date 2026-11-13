import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Một khối của trang chỉnh sửa hồ sơ: thẻ nền trắng, tiêu đề đậm rồi nội dung
class EditProfileSection extends StatelessWidget {
  const EditProfileSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
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
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
