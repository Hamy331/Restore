import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Tiêu đề một khu trên trang chủ, có thể kèm nút "Xem tất cả"
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionHeader({
    super.key,
    required this.title,
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
              child: Text(
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
}
