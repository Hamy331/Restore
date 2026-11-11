import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';

/// Khung một mục của trang quảng bá: icon, tiêu đề, nội dung
class PromotionSection extends StatelessWidget {
  const PromotionSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.leading,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  /// Thay icon (VD ảnh HOT SALE)
  final Widget? leading;

  @override
  Widget build(BuildContext context) => AppGlassContainer(
    padding: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            leading ??
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primaryDark),
                ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/// Nhãn nhỏ bo tròn: "Đang chạy", "Lượt tặng"...
class PromotionChip extends StatelessWidget {
  const PromotionChip({
    super.key,
    required this.label,
    this.color = AppColors.success,
    this.background = AppColors.successBg,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

/// Dòng "đang chạy đến ..." màu xanh
class PromotionRunningLine extends StatelessWidget {
  const PromotionRunningLine({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(AppIcons.checkCircle, size: 16, color: AppColors.success),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
    ],
  );
}
