import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/localized_text.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/shared/models/listing_filter.dart';

/// Danh mục con (VD Điện tử › Điện thoại), nằm trong danh mục
/// cha. Mỗi danh mục con có thêm thuộc tính và bộ lọc riêng.
class SubcategoryModel extends Equatable {
  final String id;
  final LocalizedText name;
  final List<CategoryAttributeModel> attributes;

  /// Null thì theo danh mục cha
  final bool? hasCondition;

  /// Đầu trên thanh trượt giá trong bộ lọc (VND)
  final int? priceMax;

  const SubcategoryModel({
    required this.id,
    required this.name,
    this.attributes = const [],
    this.hasCondition,
    this.priceMax,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) =>
      SubcategoryModel(
        id: '${json['id']}',
        name: LocalizedText.fromJson(json['name'] ?? json['id']),
        attributes: [
          for (final attribute in json['attributes'] as List? ?? const [])
            CategoryAttributeModel.fromJson(
              Map<String, dynamic>.from(attribute as Map),
            ),
        ],
        hasCondition: json['hasCondition'] as bool?,
        priceMax: (json['priceMax'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.toJson(),
    'attributes': [for (final attribute in attributes) attribute.toJson()],
    if (hasCondition != null) 'hasCondition': hasCondition,
    'priceMax': ?priceMax,
  };

  @override
  List<Object?> get props => [id, name, attributes, hasCondition, priceMax];
}

/// Danh mục đăng tin, nhận từ API `GET /catalog/categories`.
/// Mỗi danh mục tự mang bộ thuộc tính riêng nên app hỗ trợ mọi loại hàng.
/// Danh mục cha có [subcategories]; [withSubcategory] trả bản đã gộp thuộc
/// tính của một danh mục con để form, preview và trang chi tiết dùng như cũ.
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

  /// Danh mục con (rỗng nếu danh mục chưa chia con)
  final List<SubcategoryModel> subcategories;

  /// Danh mục con đã gộp vào [attributes] (null là danh mục cha)
  final SubcategoryModel? subcategory;

  /// Đầu trên thanh trượt giá trong bộ lọc (VND), theo danh mục con nếu đã gộp
  final int? priceMax;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconKey,
    this.imageUrl,
    this.attributes = const [],
    this.hasCondition = true,
    this.subcategories = const [],
    this.subcategory,
    this.priceMax,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final subcategory = json['subcategory'];
    final subcategories = [
      for (final item in json['subcategories'] as List? ?? const [])
        SubcategoryModel.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    return CategoryModel(
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
      priceMax: (json['priceMax'] as num?)?.toInt(),
      subcategories: subcategories,
      // Trang chi tiết tin: API đã gộp thuộc tính, chỉ cần biết danh mục con
      subcategory: subcategory is Map
          ? _findSubcategory(subcategories, '${subcategory['id']}') ??
                SubcategoryModel.fromJson(
                  Map<String, dynamic>.from(subcategory),
                )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.toJson(),
    'description': description.toJson(),
    'icon': iconKey,
    'imageUrl': imageUrl,
    'attributes': [for (final attribute in attributes) attribute.toJson()],
    'hasCondition': hasCondition,
    'priceMax': ?priceMax,
    'subcategories': [for (final item in subcategories) item.toJson()],
    if (subcategory != null)
      'subcategory': {
        'id': subcategory!.id,
        'name': subcategory!.name.toJson(),
      },
  };

  bool get hasSubcategories => subcategories.isNotEmpty;

  SubcategoryModel? subcategoryOf(String? id) =>
      _findSubcategory(subcategories, id);

  static SubcategoryModel? _findSubcategory(
    List<SubcategoryModel> items,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Bản đã gộp thuộc tính chung + thuộc tính của danh mục con [subcategoryId]
  /// (con ghi đè key trùng), hasCondition theo con nếu con có khai báo.
  /// Id lạ hoặc null thì trả chính danh mục này.
  CategoryModel withSubcategory(String? subcategoryId) {
    final child = subcategoryOf(subcategoryId);
    if (child == null) return this;
    final own = {for (final attribute in child.attributes) attribute.key};
    return CategoryModel(
      id: id,
      name: name,
      description: description,
      iconKey: iconKey,
      imageUrl: imageUrl,
      attributes: [
        ...attributes.where((attribute) => !own.contains(attribute.key)),
        ...child.attributes,
      ],
      hasCondition: child.hasCondition ?? hasCondition,
      subcategories: subcategories,
      subcategory: child,
      priceMax: child.priceMax ?? priceMax,
    );
  }

  /// Có thuộc tính bảo hành: lọc tình trạng có thêm "Còn bảo hành" (Điện tử)
  bool get hasWarranty =>
      attributes.any((item) => item.key == ListingFilter.warrantyKey);

  /// Thuộc tính dùng làm bộ lọc (của danh mục con nếu đã gộp)
  List<CategoryAttributeModel> get filterAttributes => [
    for (final attribute in attributes)
      if (attribute.filter != null) attribute,
  ];

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    iconKey,
    imageUrl,
    attributes,
    hasCondition,
    subcategories,
    subcategory,
    priceMax,
  ];
}
