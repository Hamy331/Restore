import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

class AppChoiceItem<T> {
  final T value;
  final String label;
  const AppChoiceItem(this.value, this.label);
}

/// Nhóm nút chọn một giá trị dạng viên thuốc:
/// đang chọn nền tối chữ trắng, chưa chọn nền kính mờ
class AppChoiceChips<T> extends StatelessWidget {
  final List<AppChoiceItem<T>> items;
  final T? selected;
  final ValueChanged<T> onSelected;
  final WrapAlignment alignment;

  const AppChoiceChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.alignment = WrapAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          _ChoiceChip(
            label: item.label,
            isSelected: item.value == selected,
            onTap: () => onSelected(item.value),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static final BorderRadius _radius = BorderRadius.circular(20);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: _radius,
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          curve: AppAnimationDurations.enterCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimary : AppGlass.fillStrong,
            borderRadius: _radius,
            border: Border.all(
              color: isSelected ? AppColors.textPrimary : AppGlass.stroke,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppAnimationDurations.fast,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.surface : AppColors.textPrimary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
