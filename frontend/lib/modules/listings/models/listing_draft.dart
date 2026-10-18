import 'package:equatable/equatable.dart';
import 'package:restore/modules/location/models/address_info.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'listing_enums.dart';

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
  });

  String? get coverImage => images.isEmpty ? null : images.first;

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
    );
  }

  /// Payload gửi `POST /listings`. Thuộc tính được đổi đúng kiểu theo schema
  /// của danh mục; [imageUrls] là ảnh đã tải lên (thay cho đường dẫn trên máy).
  Map<String, dynamic> toPayload({
    required CategoryModel? category,
    List<String>? imageUrls,
  }) {
    final attributeValues = <String, Object>{
      for (final attribute in category?.attributes ?? const [])
        if (attribute.parse(attributes[attribute.key]) case final value?)
          attribute.key: value,
    };
    return {
      'categoryId': categoryId,
      'images': imageUrls ?? images,
      'title': title.trim(),
      'description': description.trim(),
      'allowSale': tradeType.allowsSale,
      'allowExchange': tradeType.allowsExchange,
      'price': tradeType.requiresPrice ? price : null,
      'isNegotiable': tradeType.requiresPrice && isNegotiable,
      'exchangeWish': tradeType.allowsExchange ? exchangeWish.trim() : null,
      'condition': condition?.apiValue,
      'sellerType': sellerType.name.toUpperCase(),
      'location': address?.toPayload(),
      'attributes': attributeValues,
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
  ];
}
