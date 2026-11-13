import 'package:flutter/widgets.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/data/models/category_attribute_model.dart';

/// Hiển thị giá trị thuộc tính cho người mua (xem trước, trang chi tiết tin)
class AttributeValueFormatter {
  AttributeValueFormatter._();

  /// Null khi chưa nhập, để nơi gọi tự quyết định ẩn hay hiện "Chưa cập nhật"
  static String? format(
    BuildContext context,
    CategoryAttributeModel attribute,
    String? raw,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    return switch (attribute.type) {
      AttributeType.select =>
        attribute.optionOf(value)?.label.of(context) ?? value,
      AttributeType.boolean => value == 'true' ? l10n.yes : l10n.no,
      AttributeType.number => _number(context, attribute, value),
      AttributeType.text => value,
    };
  }

  /// Số kèm đơn vị; có nhiều đơn vị thì chọn đơn vị gọn nhất (24 tháng → 2 năm)
  static String _number(
    BuildContext context,
    CategoryAttributeModel attribute,
    String value,
  ) {
    final number = num.tryParse(value);
    if (attribute.bestUnitFor(number) case final unit? when number != null) {
      final shown = number % unit.factor == 0
          ? '${number ~/ unit.factor}'
          : '${number / unit.factor}';
      return '$shown ${unit.label.of(context)}';
    }
    return switch (attribute.unit?.of(context)) {
      final unit? => '$value $unit',
      null => value,
    };
  }
}
