import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/localized_text.dart';
import 'package:restore/data/models/category_attribute_model.dart';

/// Danh mục đăng tin, nhận từ API `GET /catalog/categories`.
/// Mỗi danh mục tự mang bộ thuộc tính riêng nên app hỗ trợ mọi loại hàng.
class CategoryModel extends Equatable {
  final String id;
  final LocalizedText name;
  final LocalizedText description;

  /// Khoá icon dự phòng khi chưa có ảnh (xem AppIcons.forCategory)
  final String? iconKey;

  /// Ảnh danh mục: URL từ API hoặc đường dẫn asset khi dùng dữ liệu mẫu
  final String? imageUrl;
  final List<CategoryAttributeModel> attributes;

  /// Danh mục có hỏi tình trạng hàng không (Mới, Như mới...). Thú cưng thì không.
  final bool hasCondition;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconKey,
    this.imageUrl,
    this.attributes = const [],
    this.hasCondition = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: '${json['id']}',
    name: LocalizedText.fromJson(json['name']),
    description: LocalizedText.fromJson(json['description']),
    iconKey: json['icon'] as String?,
    imageUrl: json['imageUrl'] as String?,
    attributes: [
      for (final attribute in json['attributes'] as List? ?? const [])
        CategoryAttributeModel.fromJson(
          Map<String, dynamic>.from(attribute as Map),
        ),
    ],
    hasCondition: json['hasCondition'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.toJson(),
    'description': description.toJson(),
    'icon': iconKey,
    'imageUrl': imageUrl,
    'attributes': [for (final attribute in attributes) attribute.toJson()],
    'hasCondition': hasCondition,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    iconKey,
    imageUrl,
    attributes,
    hasCondition,
  ];
}
