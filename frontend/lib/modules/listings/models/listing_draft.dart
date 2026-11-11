import 'package:equatable/equatable.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'listing_enums.dart';
import 'package:restore/data/models/listing_model.dart';

/// Dữ liệu tin đăng đang soạn, dùng chung cho cả 3 bước và trang xem trước
class ListingDraft extends Equatable {
  static const int maxImages = 20;
  static const int minTitleLength = 5;
  static const int maxTitleLength = 70;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 1500;
  static const int maxExchangeWishLength = 200;

  final String? id;
  final String categoryId;

  /// Đường dẫn ảnh trên máy hoặc URL đã tải lên. Ảnh đầu tiên là ảnh bìa.
  final List<String> images;
  final String title;
  final String description;
  final TradeType tradeType;
  final int? price; // VND
  final bool isNegotiable;
  final String exchangeWish;
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
    this.images = const [],
    this.title = '',
    this.description = '',
    this.tradeType = TradeType.sell,
    this.price,
    this.isNegotiable = true,
    this.exchangeWish = '',
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
      exchangeWish.trim().isNotEmpty ||
      address != null ||
      condition != null ||
      attributes.values.any((value) => value.trim().isNotEmpty);

  /// Cùng nội dung người dùng nhập (bỏ qua id, trạng thái, thời điểm lưu
  /// và loại người bán vốn lấy theo tài khoản)
  bool sameContentAs(ListingDraft other) =>
      _ContentKey(this) == _ContentKey(other);

  factory ListingDraft.fromListing(ListingModel model) => ListingDraft(
    id: model.id,
    categoryId: model.categoryId ?? '',
    title: model.title,
    description: model.description,
    images: model.images,
    price:
        model.status == ListingStatus.draft &&
            model.allowSale &&
            model.price == 0
        ? null
        : model.price,
    condition: model.condition,
    isNegotiable: model.isNegotiable,
    tradeType: model.allowSale
        ? (model.allowExchange ? TradeType.sellOrExchange : TradeType.sell)
        : TradeType.exchange,
    exchangeWish: model.exchangeWish,
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

  ListingDraft copyWith({
    String? id,
    String? categoryId,
    List<String>? images,
    String? title,
    String? description,
    TradeType? tradeType,
    int? Function()? price,
    bool? isNegotiable,
    String? exchangeWish,
    AddressInfo? address,
    SellerType? sellerType,
    ListingCondition? condition,
    Map<String, String>? attributes,
    ListingStatus? status,
    DateTime? updatedAt,
    int? Function()? displayDays,
    DateTime? Function()? startsAt,
  }) {
    return ListingDraft(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      images: images ?? this.images,
      title: title ?? this.title,
      description: description ?? this.description,
      tradeType: tradeType ?? this.tradeType,
      price: price != null ? price() : this.price,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      exchangeWish: exchangeWish ?? this.exchangeWish,
      address: address ?? this.address,
      sellerType: sellerType ?? this.sellerType,
      condition: condition ?? this.condition,
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
      'title': title.trim(),
      'description': description.trim(),
      'allowSale': tradeType.allowsSale,
      'allowExchange': tradeType.allowsExchange,
      'price': tradeType.requiresPrice ? '${price ?? 0}' : '0',
      'isNegotiable': tradeType.requiresPrice && isNegotiable,
      'exchangeWish': tradeType.allowsExchange ? exchangeWish.trim() : '',
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
    images,
    title,
    description,
    tradeType,
    price,
    isNegotiable,
    exchangeWish,
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
        draft.images,
        draft.title.trim(),
        draft.description.trim(),
        draft.tradeType,
        draft.price,
        draft.isNegotiable,
        draft.exchangeWish.trim(),
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
