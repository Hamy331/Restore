import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/localized_text.dart';
import 'category_attribute.dart';

/// Danh mục đăng tin, nhận từ API `GET /categories`.
/// Mỗi danh mục tự mang bộ thuộc tính riêng nên app hỗ trợ mọi loại hàng.
class ListingCategory extends Equatable {
  final String id;
  final LocalizedText name;
  final LocalizedText description;

  /// Khoá icon dự phòng khi chưa có ảnh (xem CategoryIcons)
  final String? iconKey;

  /// Ảnh danh mục: URL từ API hoặc đường dẫn asset khi dùng dữ liệu mẫu
  final String? imageUrl;
  final List<CategoryAttribute> attributes;

  const ListingCategory({
    required this.id,
    required this.name,
    required this.description,
    this.iconKey,
    this.imageUrl,
    this.attributes = const [],
  });

  factory ListingCategory.fromJson(Map<String, dynamic> json) =>
      ListingCategory(
        id: '${json['id']}',
        name: LocalizedText.fromJson(json['name']),
        description: LocalizedText.fromJson(json['description']),
        iconKey: json['icon'] as String?,
        imageUrl: json['imageUrl'] as String?,
        attributes: [
          for (final attribute in json['attributes'] as List? ?? const [])
            CategoryAttribute.fromJson(
              Map<String, dynamic>.from(attribute as Map),
            ),
        ],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.toJson(),
    'description': description.toJson(),
    'icon': iconKey,
    'imageUrl': imageUrl,
    'attributes': [for (final attribute in attributes) attribute.toJson()],
  };

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    iconKey,
    imageUrl,
    attributes,
  ];
}
