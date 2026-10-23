import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/data/models/category_model.dart';
import '../models/listing_draft.dart';

/// Các trường có thể báo lỗi ở bước 2
enum ListingField { photos, description, title, price, location }

/// Lỗi của một thuộc tính ở bước 3
enum AttributeError { required, outOfRange }

/// Kiểm tra dữ liệu tin đăng theo từng bước.
/// Backend cũng kiểm tra lại theo cùng schema thuộc tính.
class ListingValidator {
  ListingValidator._();

  /// Khoá riêng cho trường Tình trạng (dùng chung mọi danh mục)
  static const String conditionKey = 'condition';

  static Set<ListingField> basicInfoErrors(ListingDraft draft) => {
    if (draft.images.isEmpty) ListingField.photos,
    if (draft.description.trim().length < ListingDraft.minDescriptionLength ||
        draft.description.trim().length > ListingDraft.maxDescriptionLength)
      ListingField.description,
    if (draft.title.trim().length < ListingDraft.minTitleLength ||
        draft.title.trim().length > ListingDraft.maxTitleLength)
      ListingField.title,
    if (draft.tradeType.requiresPrice &&
        ((draft.price ?? 0) <= 0 || (draft.price ?? 0) > 999999999999))
      ListingField.price,
    if (draft.address == null) ListingField.location,
  };

  /// Lỗi ở bước 3, theo khoá thuộc tính (và [conditionKey])
  static Map<String, AttributeError> detailErrors(
    ListingDraft draft,
    CategoryModel? category,
  ) => {
    if (draft.condition == null) conditionKey: AttributeError.required,
    for (final attribute
        in category?.attributes ?? const <CategoryAttributeModel>[])
      if (_errorOf(attribute, draft.attributes[attribute.key])
          case final error?)
        attribute.key: error,
  };

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

  static bool isBasicInfoValid(ListingDraft draft) =>
      basicInfoErrors(draft).isEmpty;

  static bool isReadyToPublish(ListingDraft draft, CategoryModel? category) =>
      category != null &&
      isBasicInfoValid(draft) &&
      detailErrors(draft, category).isEmpty;
}
