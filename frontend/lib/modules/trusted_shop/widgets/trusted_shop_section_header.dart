import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Tiêu đề một khu trên các trang shop, dẫn dắt bằng chữ thay cho icon:
/// dòng nhãn nhỏ in hoa màu nhấn kèm gạch ngắn (tuỳ chọn), tên khu chữ lớn,
/// dòng phụ (tuỳ chọn) và một nút bên phải (VD chip sắp xếp, "Xem tất cả")
class TrustedShopSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Nhãn ngắn phía trên tên khu (VD "Chính hãng"), tự in hoa
  final String? eyebrow;
  final Color accent;

  /// Tô dòng phụ bằng màu nhấn, dùng khi dòng phụ là thông tin chính
  /// (VD "Giảm đến 50%")
  final bool highlightSubtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const TrustedShopSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.accent = AppColors.primaryDark,
    this.highlightSubtitle = false,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final eyebrow = this.eyebrow;
    final trailing = this.trailing;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 2,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          eyebrow.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: highlightSubtitle
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: highlightSubtitle
                          ? accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
  }
}
