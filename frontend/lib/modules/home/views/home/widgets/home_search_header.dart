import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';

import 'home_header_icon_button.dart';

/// Ô tìm kiếm ghim ở đầu trang khi cuộn, bên phải là nút tin nhắn và thông
/// báo. Nền đổi theo trạng thái ghim qua [AppPinnedHeaderSurface].
class HomeSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String hintText;
  final VoidCallback onTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onNotificationsTap;

  HomeSearchHeaderDelegate({
    required this.hintText,
    required this.onTap,
    required this.onMessagesTap,
    required this.onNotificationsTap,
  });

  static const double height = 68;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return AppPinnedHeaderSurface(
      pinned: overlapsContent || shrinkOffset > 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: AppSearchPill(text: hintText, onTap: onTap),
            ),
            const SizedBox(width: 8),
            HomeHeaderIconButton(
              icon: AppIcons.chat,
              tooltip: l10n.messagesTitle,
              onTap: onMessagesTap,
            ),
            const SizedBox(width: 8),
            HomeHeaderIconButton(
              icon: AppIcons.notification,
              tooltip: l10n.notifications,
              onTap: onNotificationsTap,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(HomeSearchHeaderDelegate oldDelegate) =>
      oldDelegate.hintText != hintText ||
      oldDelegate.onTap != onTap ||
      oldDelegate.onMessagesTap != onMessagesTap ||
      oldDelegate.onNotificationsTap != onNotificationsTap;
}
