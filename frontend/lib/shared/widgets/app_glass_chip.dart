import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Chip viền mảnh trên nền kính: icon + nhãn. Đang chọn thì viền và chữ
/// màu ấm; có [onClear] thì hiện nút x nhỏ để bỏ giá trị.
class AppGlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool isSelected;

  /// Nhãn dài hơn thì cắt bằng dấu ...
  final double maxLabelWidth;

  const AppGlassChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.onClear,
    this.isSelected = false,
    this.maxLabelWidth = 180,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryDark : AppColors.textPrimary;
    final radius = BorderRadius.circular(14);
    return AnimatedContainer(
      duration: AppAnimationDurations.normal,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: isSelected
            ? AppColors.primarySoft.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.6),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.border,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 9, onClear == null ? 14 : 6, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxLabelWidth),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                if (onClear != null)
                  InkResponse(
                    onTap: onClear,
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(AppIcons.close, size: 16, color: color),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
