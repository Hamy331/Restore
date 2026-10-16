import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/l10n/app_localizations.dart';

import 'home_header_icon_button.dart';

import 'home_header_palette.dart';

/// Ô tìm kiếm ghim ở đầu trang khi cuộn, bên phải là nút tin nhắn và thông
/// báo.
/// Bình thường liền màu với đầu trang; khi đã ghim thì nền chuyển sang
/// kính mờ trắng với một đường mảnh phía dưới.
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

  /// Nền kính khi đã ghim, dùng chung với dải thanh trạng thái phía trên
  static final Color pinnedColor = Colors.white.withValues(alpha: 0.86);

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
    final pinned = overlapsContent || shrinkOffset > 0;
    // Giữ nguyên cấu trúc cây ở cả hai trạng thái, chỉ bật/tắt hiệu ứng
    return ClipRect(
      child: BackdropFilter(
        enabled: pinned,
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: pinned ? pinnedColor : HomeHeaderPalette.bottom,
            border: Border(
              bottom: BorderSide(
                color: pinned
                    ? AppColors.border.withValues(alpha: 0.8)
                    : HomeHeaderPalette.bottom,
                width: 0.6,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SearchPill(hintText: hintText, onTap: onTap),
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

class _SearchPill extends StatelessWidget {
  final String hintText;
  final VoidCallback onTap;

  const _SearchPill({required this.hintText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(
                  AppIcons.search,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hintText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
