import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Hàng tab chữ chia đều bề ngang, tab đang chọn đậm và có gạch chân màu
/// chính. Dùng trong phần ghim đầu trang (VD Tin đăng / Cửa hàng / Người
/// dùng ở trang kết quả tìm kiếm), không cần TabController.
class AppUnderlineTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;

  /// Nằm trên nền xanh của phần đầu (chưa ghim): chữ trắng cho dễ đọc
  final bool onDark;

  static const double height = 40;

  const AppUnderlineTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == selectedIndex,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onChanged(i),
                    child: _Tab(
                      label: labels[i],
                      selected: i == selectedIndex,
                      onDark: onDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final bool onDark;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedDefaultTextStyle(
          duration: AppAnimationDurations.fast,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: onDark
                ? (selected ? Colors.white : Colors.white70)
                : (selected ? AppColors.textPrimary : AppColors.textSecondary),
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: AppAnimationDurations.fast,
          height: 3,
          width: selected ? 28 : 0,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
