import 'package:equatable/equatable.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'listing_enums.dart';
import 'package:restore/data/models/listing_model.dart';

/// Dữ liệu tin đăng đang soạn, dùng chung cho cả 3 bước (danh mục, thông
/// tin sản phẩm, xem trước & đăng)
class ListingDraft extends Equatable {
  static const int maxImages = 20;
  static const int minTitleLength = 5;
  static const int maxTitleLength = 70;
  static const int maxDescriptionLength = 1500;

  final String? id;
  final String categoryId;

  /// Danh mục con đã chọn (rỗng khi danh mục chưa chia con)
  final String subcategoryId;

  /// Đường dẫn ảnh trên máy hoặc URL đã tải lên. Ảnh đầu tiên là ảnh bìa.
  final List<String> images;
  final String title;

  /// Mô tả (không bắt buộc)
  final String description;

  /// Cho tặng miễn phí: không có giá, không nhận trả giá
  final bool isFree;
  final int? price; // VND

  /// Giá cố định: người mua chỉ đề nghị đúng giá đăng
  final bool fixedPrice;

  /// Có nhiều món giống nhau: nhận đề nghị không giữ hàng cho riêng ai
  final bool multipleUnits;

  /// Gặp mặt giao dịch tại [address]
  final bool meetUp;
  final AddressInfo? address;
  final SellerType sellerType;
  final ListingCondition? condition;

  /// Giá trị thuộc tính theo danh mục (key → giá trị dạng chuỗi trên form)
  final Map<String, String> attributes;
  final ListingStatus status;
  final DateTime? updatedAt;

  /// Số ngày hiển thị người bán chọn (null = số ngày miễn phí của chuyên mục)
  final int? displayDays;

  /// Ngày hẹn bắt đầu hiển thị (null = ngay khi được duyệt)
  final DateTime? startsAt;

  const ListingDraft({
    this.id,
    this.categoryId = '',
    this.subcategoryId = '',
    this.images = const [],
    this.title = '',
    this.description = '',
    this.isFree = false,
    this.price,
    this.fixedPrice = false,
    this.multipleUnits = false,
    this.meetUp = true,
    this.address,
    this.sellerType = SellerType.personal,
    this.condition,
    this.attributes = const {},
    this.status = ListingStatus.draft,
    this.updatedAt,
    this.displayDays,
    this.startsAt,
  });

  String? get coverImage => images.isEmpty ? null : images.first;

  /// Người dùng đã nhập gì đó đáng lưu nháp (chỉ chọn danh mục thì chưa tính)
  bool get hasContent =>
      images.isNotEmpty ||
      title.trim().isNotEmpty ||
      description.trim().isNotEmpty ||
      price != null ||
      isFree ||
      address != null ||
      condition != null ||
      attributes.values.any((value) => value.trim().isNotEmpty);

  /// Cùng nội dung người dùng nhập (bỏ qua id, trạng thái, thời điểm lưu
  /// và loại người bán vốn lấy theo tài khoản)
  bool sameContentAs(ListingDraft other) =>
      _ContentKey(this) == _ContentKey(other);

  factory ListingDraft.fromListing(ListingModel model) {
    final isDraft = model.status == ListingStatus.draft;
    // Tin cũ chỉ trao đổi (không bán) mở ra như tin bán chưa nhập giá
    final hasPrice = model.allowSale && !model.isFree && (model.price ?? 0) > 0;
    return ListingDraft(
      id: model.id,
      categoryId: model.categoryId ?? '',
      subcategoryId: model.subcategoryId ?? '',
      title: model.title,
      description: model.description,
      images: model.images,
      isFree: model.isFree,
      price: hasPrice ? model.price : null,
      fixedPrice: model.allowSale && !model.isFree && !model.isNegotiable,
      multipleUnits: model.multipleUnits,
      // Nháp chưa chọn địa chỉ vẫn mặc định gặp mặt
      meetUp: model.meetUp || (isDraft && model.address == null),
      condition: model.condition,
      address: model.address,
      sellerType: model.sellerType == 'BUSINESS'
          ? SellerType.business
          : SellerType.personal,
      attributes: model.attributes.map((key, value) => MapEntry(key, '$value')),
      status: model.status,
      updatedAt: model.updatedAt,
      displayDays: model.displayDays,
      startsAt: model.startsAt,
    );
  }

  ListingDraft copyWith({
    String? id,
    String? categoryId,
    String? subcategoryId,
    List<String>? images,
    String? title,
    String? description,
    bool? isFree,
    int? Function()? price,
    bool? fixedPrice,
    bool? multipleUnits,
    bool? meetUp,
    AddressInfo? address,
    SellerType? sellerType,
    ListingCondition? Function()? condition,
    Map<String, String>? attributes,
    ListingStatus? status,
    DateTime? updatedAt,
    int? Function()? displayDays,
    DateTime? Function()? startsAt,
  }) {
    return ListingDraft(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      images: images ?? this.images,
      title: title ?? this.title,
      description: description ?? this.description,
      isFree: isFree ?? this.isFree,
      price: price != null ? price() : this.price,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      multipleUnits: multipleUnits ?? this.multipleUnits,
      meetUp: meetUp ?? this.meetUp,
      address: address ?? this.address,
      sellerType: sellerType ?? this.sellerType,
      condition: condition != null ? condition() : this.condition,
      attributes: attributes ?? this.attributes,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      displayDays: displayDays != null ? displayDays() : this.displayDays,
      startsAt: startsAt != null ? startsAt() : this.startsAt,
    );
  }

  /// Thuộc tính được đổi đúng kiểu theo schema; ảnh tải riêng bằng API media.
  Map<String, dynamic> toPayload({required CategoryModel? category}) {
    final attributeValues = <String, Object>{
      for (final attribute in category?.attributes ?? const [])
        if (attribute.parse(attributes[attribute.key]) case final value?)
          attribute.key: value,
    };
    return {
      'categoryId': categoryId,
      'subcategoryId': subcategoryId.isEmpty ? null : subcategoryId,
      'title': title.trim(),
      'description': description.trim(),
      'allowSale': true,
      'allowExchange': false,
      'isFree': isFree,
      'price': isFree ? '0' : '${price ?? 0}',
      'isNegotiable': !isFree && !fixedPrice,
      'multipleUnits': multipleUnits,
      'meetUp': meetUp,
      // Danh mục không hỏi tình trạng (thú cưng) thì không gửi
      'condition': (category?.hasCondition ?? true)
          ? condition?.apiValue
          : null,
      'sellerType': sellerType.name.toUpperCase(),
      'location': address?.toPayload(),
      'attributes': attributeValues,
      'displayDays': displayDays,
      'startsAt': startsAt?.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    subcategoryId,
    images,
    title,
    description,
    isFree,
    price,
    fixedPrice,
    multipleUnits,
    meetUp,
    address,
    sellerType,
    condition,
    attributes,
    status,
    updatedAt,
    displayDays,
    startsAt,
  ];
}

/// Phần nội dung người dùng nhập của [ListingDraft], dùng để so sánh
class _ContentKey extends Equatable {
  _ContentKey(ListingDraft draft)
    : props = [
        draft.categoryId,
        draft.subcategoryId,
        draft.images,
        draft.title.trim(),
        draft.description.trim(),
        draft.isFree,
        draft.price,
        draft.fixedPrice,
        draft.multipleUnits,
        draft.meetUp,
        draft.address,
        draft.condition,
        {
          for (final entry in draft.attributes.entries)
            if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
        },
        draft.displayDays,
        draft.startsAt,
      ];

  @override
  final List<Object?> props;
}
