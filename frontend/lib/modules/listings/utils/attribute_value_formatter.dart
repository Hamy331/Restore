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
      AttributeType.number => switch (attribute.unit?.of(context)) {
        final unit? => '$value $unit',
        null => value,
      },
      AttributeType.text => value,
    };
  }
}
