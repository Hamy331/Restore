import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Ô tìm kiếm dạng viên thuốc trắng, chạm để mở trang tìm kiếm / chọn địa
/// điểm (không gõ trực tiếp). Dùng chung cho trang chủ, gần bạn, danh mục...
///
/// [isPlaceholder] true thì [text] là gợi ý (chữ xám), false là giá trị đang
/// chọn (chữ đậm, VD tên khu vực). [trailing] đặt cuối ô, VD nút "Đổi".
class AppSearchPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData icon;
  final bool isPlaceholder;
  final Widget? trailing;
  final double height;

  const AppSearchPill({
    super.key,
    required this.text,
    required this.onTap,
    this.icon = AppIcons.search,
    this.isPlaceholder = true,
    this.trailing,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(icon, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isPlaceholder
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: isPlaceholder
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                  const SizedBox(width: 6),
                ] else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
