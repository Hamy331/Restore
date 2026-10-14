import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ListingChoiceItem<T> {
  final T value;
  final String label;
  const ListingChoiceItem(this.value, this.label);
}

/// Nhóm nút chọn dạng viên thuốc: đang chọn nền tối, chưa chọn nền kem
class ListingChoiceChips<T> extends StatelessWidget {
  final List<ListingChoiceItem<T>> items;
  final T? selected;
  final ValueChanged<T> onSelected;
  final WrapAlignment alignment;

  const ListingChoiceChips({
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
      children: items.map((item) {
        final isSelected = item.value == selected;
        return InkWell(
          onTap: () => onSelected(item.value),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textPrimary : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
