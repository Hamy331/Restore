import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';

import 'home_header_icon_button.dart';
import 'home_notification_button.dart';

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

  static const double height = 60;

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
      blurWhenPinned: false,
      showDivider: false,
      pinned: overlapsContent || shrinkOffset > 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: AppSearchPill(
                text: hintText,
                onTap: onTap,
                height: 44,
                iconColor: AppHeaderPalette.top,
                showBorder: false,
                showShadow: false,
              ),
            ),
            const SizedBox(width: 8),
            HomeHeaderIconButton(
              icon: AppIcons.chat,
              tooltip: l10n.messagesTitle,
              onTap: onMessagesTap,
            ),
            const SizedBox(width: 8),
            HomeNotificationButton(
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
