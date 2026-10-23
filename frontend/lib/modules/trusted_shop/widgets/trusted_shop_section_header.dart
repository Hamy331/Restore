import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Tiêu đề một khu trên các trang shop: icon trong ô màu nhạt, tên khu,
/// dòng phụ (tuỳ chọn) và một nút bên phải (VD chip sắp xếp, "Xem tất cả")
class TrustedShopSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;

  const TrustedShopSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primaryDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final icon = this.icon;
    final trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
  }
}
