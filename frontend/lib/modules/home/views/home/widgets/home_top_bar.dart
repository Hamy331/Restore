import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Đầu trang chủ trên nền cam: chọn khu vực, bên dưới là lời chào kèm tên
/// người dùng. Nút tin nhắn và thông báo nằm cạnh ô tìm kiếm ghim
/// ([HomeSearchHeaderDelegate]) để luôn bấm được khi cuộn.
class HomeTopBar extends StatelessWidget {
  final String areaName;
  final String greetingName;
  final VoidCallback onAreaTap;

  const HomeTopBar({
    super.key,
    required this.areaName,
    required this.greetingName,
    required this.onAreaTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppHeaderPalette.gradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AreaButton(
              areaName: areaName,
              tooltip: l10n.homeChangeArea,
              onTap: onAreaTap,
            ),
            const SizedBox(height: 16),
            Text(
              greetingName.isEmpty
                  ? l10n.homeGreeting
                  : l10n.homeGreetingName(greetingName),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.homeHeadline,
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút khu vực: viên thuốc trắng trên nền cam kem
class _AreaButton extends StatelessWidget {
  final String areaName;
  final String tooltip;
  final VoidCallback onTap;

  const _AreaButton({
    required this.areaName,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  AppIcons.location,
                  size: 17,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    areaName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  AppIcons.chevronDown,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
