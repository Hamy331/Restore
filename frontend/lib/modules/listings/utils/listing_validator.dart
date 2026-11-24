import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/data/models/category_model.dart';
import '../models/listing_draft.dart';

/// Các trường có thể báo lỗi ở bước Thông tin sản phẩm
enum ListingField { photos, title, condition, price, location }

/// Lỗi của một thuộc tính theo danh mục
enum AttributeError { required, outOfRange }

/// Lỗi của tin đang soạn: trường chung và thuộc tính theo danh mục
class ListingErrors {
  const ListingErrors({this.fields = const {}, this.attributes = const {}});

  static const ListingErrors none = ListingErrors();

  final Set<ListingField> fields;
  final Map<String, AttributeError> attributes;

  bool get isEmpty => fields.isEmpty && attributes.isEmpty;
  bool has(ListingField field) => fields.contains(field);
}

/// Kiểm tra dữ liệu tin đăng trước khi sang bước xem trước / đăng tin.
/// Backend cũng kiểm tra lại theo cùng schema thuộc tính.
class ListingValidator {
  ListingValidator._();

  static ListingErrors errors(ListingDraft draft, CategoryModel? category) =>
      ListingErrors(
        fields: {
          if (draft.images.isEmpty) ListingField.photos,
          if (draft.title.trim().length < ListingDraft.minTitleLength)
            ListingField.title,
          if ((category?.hasCondition ?? true) && draft.condition == null)
            ListingField.condition,
          if (!draft.isFree && (draft.price ?? 0) <= 0) ListingField.price,
          // Khu vực luôn cần để tin hiện ở "Gần bạn" và bộ lọc khu vực
          if (draft.address == null) ListingField.location,
        },
        attributes: {
          for (final attribute
              in category?.attributes ?? const <CategoryAttributeModel>[])
            if (_errorOf(attribute, draft.attributes[attribute.key])
                case final error?)
              attribute.key: error,
        },
      );

  static AttributeError? _errorOf(
    CategoryAttributeModel attribute,
    String? raw,
  ) {
    if (attribute.parse(raw) == null) {
      // Công tắc có/không luôn có giá trị nên không tính là thiếu
      if (attribute.isRequired && attribute.type != AttributeType.boolean) {
        return AttributeError.required;
      }
      return null;
    }
    return attribute.isOutOfRange(raw) ? AttributeError.outOfRange : null;
  }

  static bool isReadyToPublish(ListingDraft draft, CategoryModel? category) =>
      category != null && errors(draft, category).isEmpty;
}
