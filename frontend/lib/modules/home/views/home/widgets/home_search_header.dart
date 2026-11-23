import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';

/// Ô tìm kiếm xám ghim ở đầu trang chủ khi cuộn. Cuối ô là khu vực đang xem
/// ("📍 Toàn quốc ▾"): bấm phần chữ để mở trang tìm kiếm, bấm khu vực để đổi
/// khu vực.
class HomeSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String hintText;
  final VoidCallback onTap;
  final String areaName;
  final String areaTooltip;
  final VoidCallback onAreaTap;

  HomeSearchHeaderDelegate({
    required this.hintText,
    required this.onTap,
    required this.areaName,
    required this.areaTooltip,
    required this.onAreaTap,
  });

  static const double height = 60;

  /// Chiều cao ô tìm kiếm
  static const double fieldHeight = 44;

  static const _fill = Color(0xFFF2F3F5);

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
    return AppPinnedHeaderSurface(
      blurWhenPinned: false,
      showDivider: false,
      color: AppColors.surface,
      pinned: overlapsContent || shrinkOffset > 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: _fill,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: fieldHeight,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          AppIcons.search,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hintText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 22, color: AppColors.border),
                Tooltip(
                  message: areaTooltip,
                  child: InkWell(
                    onTap: onAreaTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.location,
                              size: 17,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                areaName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
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
      oldDelegate.areaName != areaName ||
      oldDelegate.areaTooltip != areaTooltip ||
      oldDelegate.onAreaTap != onAreaTap;
}
