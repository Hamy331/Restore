import 'package:flutter/services.dart';
import 'listing_option.dart';

enum ListingDetailFieldType {
  /// Các lựa chọn hiển thị dạng chip ngay trên form (VD: Tình trạng)
  choice,

  /// Mở bottom sheet để chọn một giá trị (VD: Hãng, Dung lượng)
  picker,

  /// Nhập văn bản trực tiếp trên dòng (VD: Dòng máy)
  text,
}

/// Một trường trong phần "Thông tin chi tiết", khác nhau theo từng danh mục
class ListingDetailField {
  const ListingDetailField({
    required this.key,
    required this.type,
    required this.label,
    this.hint,
    this.isRequired = false,
    this.options = const [],
    this.keyboardType = TextInputType.text,
  });

  static const String conditionKey = 'condition';

  final String key;
  final ListingDetailFieldType type;
  final L10nText label;
  final L10nText? hint;
  final bool isRequired;
  final List<ListingOption> options;
  final TextInputType keyboardType;

  bool get isCondition => key == conditionKey;
}
