import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Hàng chip lọc nhanh cuộn ngang, đặt dưới ô tìm kiếm ở các trang danh sách
/// (gần bạn, kết quả tìm kiếm, danh mục...).
///
/// ```dart
/// AppFilterBar(children: [
///   AppFilterChip(label: 'Bộ lọc', icon: AppIcons.filter, onTap: ...),
///   AppFilterChip(label: 'Trong 5 km', hasDropdown: true, onTap: ...),
///   AppFilterChip(label: 'Trao đổi', selected: true, onTap: ...),
/// ])
/// ```
class AppFilterBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const AppFilterBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppFilterChip.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

/// Một chip lọc dạng viên thuốc.
/// - [selected]: nền tối chữ trắng như [AppChoiceChips].
/// - [hasDropdown]: thêm mũi tên, dùng cho chip mở danh sách chọn
///   (bán kính, sắp xếp...).
/// - [badgeCount] > 0: chấm cam đếm số tiêu chí đang bật (VD nút Bộ lọc).
class AppFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
  final bool hasDropdown;
  final int badgeCount;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.hasDropdown = false,
    this.badgeCount = 0,
  });

  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.surface : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      // Viền và nền nằm dưới, Material trong suốt ở trên để hiệu ứng chạm
      // không bị nền che
      child: AnimatedContainer(
        duration: AppAnimationDurations.fast,
        curve: AppAnimationDurations.enterCurve,
        height: height,
        decoration: ShapeDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.textPrimary : AppColors.border,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: EdgeInsets.only(
                left: icon == null ? 14 : 12,
                right: hasDropdown ? 10 : 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const ShapeDecoration(
                        color: AppColors.primary,
                        shape: StadiumBorder(),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  if (hasDropdown) ...[
                    const SizedBox(width: 2),
                    Icon(AppIcons.chevronDown, size: 16, color: foreground),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
