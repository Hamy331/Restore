import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import 'app_search_list_tile.dart';

/// Một tài khoản (cửa hàng, người dùng) trong trang tìm kiếm: ảnh đại diện,
/// tên (tô đậm phần khớp [highlight]), [badge] ngay sau tên, dòng phụ và
/// [trailing] bên phải (VD nút Theo dõi).
class AppSearchAccountTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? highlight;
  final Widget? badge;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const AppSearchAccountTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    final trailing = this.trailing;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          AppSearchListTile.highlightSpan(
                            title,
                            highlight,
                            const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(width: 4), badge],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }
}
