import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import 'following_palette.dart';

/// Dòng tiêu đề nhỏ của từng khu trên trang, kèm nút phụ bên phải
class FollowingSectionTitle extends StatelessWidget {
  const FollowingSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final actionLabel = this.actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: FollowingPalette.accent,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
