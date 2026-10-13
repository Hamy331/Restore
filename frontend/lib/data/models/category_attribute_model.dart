import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/localized_text.dart';

/// Kiểu dữ liệu của một thuộc tính, quyết định widget nhập trên form
enum AttributeType {
  /// Chọn một giá trị trong danh sách (Hãng, Kích cỡ, Loại xe...)
  select,

  /// Văn bản tự do (Dòng máy, Chất liệu...)
  text,

  /// Số, có thể kèm đơn vị và khoảng hợp lệ (Năm sản xuất, Số km, Dung tích...)
  number,

  /// Có / không (Còn giấy tờ, Đã tiêm phòng...)
  boolean;

  static AttributeType fromJson(String value) => AttributeType.values
      .firstWhere((type) => type.name == value, orElse: () => text);
}

class AttributeOption extends Equatable {
  /// Giá trị lưu xuống DB / gửi lên API
  final String value;
  final LocalizedText label;

  const AttributeOption({required this.value, required this.label});

  factory AttributeOption.fromJson(Map<String, dynamic> json) =>
      AttributeOption(
        value: '${json['value']}',
        // Không có nhãn thì hiển thị chính giá trị (tên riêng: Apple, 128 GB)
        label: LocalizedText.fromJson(json['label'] ?? json['value']),
      );

  Map<String, dynamic> toJson() => {'value': value, 'label': label.toJson()};

  @override
  List<Object?> get props => [value, label];
}

/// Một thuộc tính trong "Thông tin chi tiết", định nghĩa bởi backend cho từng
/// danh mục. Thêm loại hàng mới chỉ cần thêm dữ liệu, không phải sửa app.
class CategoryAttributeModel extends Equatable {
  final String key;
  final AttributeType type;
  final LocalizedText label;
  final LocalizedText? hint;
  final bool isRequired;
  final List<AttributeOption> options;

  /// Đơn vị hiển thị sau ô số (km, cc, W, tháng...)
  final LocalizedText? unit;
  final num? min;
  final num? max;
  final int? maxLength;

  const CategoryAttributeModel({
    required this.key,
    required this.type,
    required this.label,
    this.hint,
    this.isRequired = false,
    this.options = const [],
    this.unit,
    this.min,
    this.max,
    this.maxLength,
  });

  factory CategoryAttributeModel.fromJson(Map<String, dynamic> json) {
    final hint = json['hint'];
    final unit = json['unit'];
    return CategoryAttributeModel(
      key: json['key'] as String,
      type: AttributeType.fromJson(json['type'] as String),
      label: LocalizedText.fromJson(json['label']),
      hint: hint == null ? null : LocalizedText.fromJson(hint),
      isRequired: json['required'] as bool? ?? false,
      options: [
        for (final option in json['options'] as List? ?? const [])
          AttributeOption.fromJson(Map<String, dynamic>.from(option as Map)),
      ],
      unit: unit == null ? null : LocalizedText.fromJson(unit),
      min: json['min'] as num?,
      max: json['max'] as num?,
      maxLength: json['maxLength'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'type': type.name,
    'label': label.toJson(),
    'hint': hint?.toJson(),
    'required': isRequired,
    'options': [for (final option in options) option.toJson()],
    'unit': unit?.toJson(),
    'min': min,
    'max': max,
    'maxLength': maxLength,
  };

  AttributeOption? optionOf(String? value) {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  /// Đổi giá trị dạng chuỗi trên form sang đúng kiểu để gửi API
  Object? parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    return switch (type) {
      AttributeType.number => num.tryParse(value),
      AttributeType.boolean => value == 'true',
      AttributeType.select || AttributeType.text => value,
    };
  }

  /// Giá trị số nằm ngoài khoảng cho phép
  bool isOutOfRange(String? raw) {
    if (type != AttributeType.number) return false;
    final value = parse(raw);
    if (value is! num) return false;
    return (min != null && value < min!) || (max != null && value > max!);
  }

  @override
  List<Object?> get props => [
    key,
    type,
    label,
    hint,
    isRequired,
    options,
    unit,
    min,
    max,
    maxLength,
  ];
}
