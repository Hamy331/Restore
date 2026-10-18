import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';

import 'app_circle_icon_button.dart';

/// Hàng tiêu đề chung của các trang con (Gần bạn, Báo khi có hàng, Shop uy
/// tín...): nút quay lại, tiêu đề đậm kèm một dòng mô tả xám và nút bên
/// phải [trailing] (tuỳ chọn). Không có nền, đặt trong [AppPageHeader] hoặc
/// header kính của trang.
class AppPageTitleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  const AppPageTitleRow({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
      child: Row(
        children: [
          AppCircleIconButton(
            icon: AppIcons.back,
            tooltip: l10n.back,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
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
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }
}

/// Đầu trang con trên nền cam kem chuyển dần như trang chủ và Gần bạn
/// ([AppHeaderPalette.gradient]). Đặt làm sliver đầu tiên để cuộn đi cùng
/// nội dung; dải thanh trạng thái phía trên dùng [AppHeaderPalette.top].
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppHeaderPalette.gradient),
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: AppPageTitleRow(
          title: title,
          subtitle: subtitle,
          onBack: onBack,
          trailing: trailing,
        ),
      ),
    );
  }
}
