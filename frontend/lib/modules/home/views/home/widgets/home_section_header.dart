import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Tiêu đề một khu trên trang chủ, có thể kèm nút "Xem tất cả"
class HomeSectionHeader extends StatelessWidget {
  final String title;

  /// Ảnh tiêu đề kiểu cụm HOT SALE (VD NEW ARRIVALS); [title] làm nhãn đọc
  /// màn hình và chữ dự phòng khi ảnh lỗi
  final String? image;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.image,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: image == null
                  ? _title()
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        label: title,
                        child: Image.asset(
                          image!,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _title(),
                        ),
                      ),
                    ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(AppIcons.chevronRight, size: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _title() => Text(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
    ),
  );
}
