import 'package:flutter/material.dart';
import 'app_choice_chips.dart';
import 'app_required_label.dart';

/// Nhãn bên trái + nhóm chip lựa chọn bên phải trên cùng một dòng
class AppLabeledChoiceRow<T> extends StatelessWidget {
  final String label;
  final bool isRequired;
  final T? selected;
  final List<AppChoiceItem<T>> items;
  final ValueChanged<T> onSelected;
  final TextStyle? labelStyle;

  const AppLabeledChoiceRow({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.isRequired = true,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppRequiredLabel(
          text: label,
          isRequired: isRequired,
          style: labelStyle,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppChoiceChips<T>(
            items: items,
            selected: selected,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }
}
