import 'shop_model.dart';
import 'dart:ui' show PlatformDispatcher;

import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/data/models/listing_revision_model.dart';
import 'package:restore/shared/models/geo_point.dart';
import 'package:restore/shared/models/localized_text.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/location/models/address_info.dart';

/// Một dòng của bảng Listing (prisma/schema.prisma), tên khoá JSON giống
/// tên cột (camelCase).
///
/// Các trường đánh dấu "(đề xuất)" chưa có trong schema hiện tại; chúng theo
/// docs/listing-api-contract.md và để null cho tới khi backend thêm cột.
class ListingModel extends Equatable {
  final String id;

  /// Mã số ngắn dùng trong URL (`/listings/tên-shortId`); null với dữ liệu cũ
  final int? shortId;
  final String ownerId;
  final String title;
  final String description;

  /// Giá VND. Cột Decimal nên API có thể trả về chuỗi hoặc số.
  final int? price;

  final bool? _isPartner;

  /// Người bán là Đối tác: gói Cửa hàng Pro còn hạn và shop đã duyệt / xác minh
  bool get isPartner => _isPartner ?? false;

  /// Trang shop của người bán, chỉ có khi [isPartner]
  final String? shopId;
  final ListingCondition? condition;
  final ListingStatus status;
  final bool allowSale;
  final bool allowExchange;

  /// Cho tặng miễn phí (giá 0, không nhận trả giá)
  final bool isFree;

  /// false = giá cố định: người mua chỉ đề nghị đúng giá đăng
  final bool isNegotiable;

  /// Người bán có nhiều món giống nhau
  final bool multipleUnits;

  /// Gặp mặt giao dịch tại khu vực của tin
  final bool meetUp;
  final List<String> images;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Hết hạn hiển thị (null = tin cũ / chưa duyệt); quá hạn thì tin tự ẩn
  final DateTime? expiresAt;

  /// Số xu đã trả cho tin (chỉ chủ tin thấy); > 0 thì tin không chiếm suất miễn phí
  final int paidCredits;

  /// Ngày hẹn bắt đầu hiển thị (null = hiện ngay khi duyệt)
  final DateTime? startsAt;

  /// Số ngày hiển thị người bán chọn lúc đăng (null = số ngày miễn phí)
  final int? displayDays;

  /// Tự gia hạn khi sắp hết hạn (chỉ chủ tin thấy, gói Cửa hàng)
  final bool autoExtend;

  /// (đề xuất) Danh mục và thuộc tính theo danh mục (jsonb)
  final String? categoryId;

  /// Danh mục con trong danh mục cha (VD dien-thoai trong electronics)
  final String? subcategoryId;
  final String categoryName;
  final Map<String, Object?> attributes;

  /// (đề xuất) Mã tỉnh/thành, phường/xã và toạ độ cho tính năng "gần bạn"
  final String? provinceCode;
  final String? wardCode;
  final GeoPoint? geoPoint;
  final AddressInfo? address;
  final String sellerName;
  final String? sellerAvatarUrl;
  final double? sellerRating;
  final int? sellerSoldCount;
  final ShopModel? shopSummary;
  final String exchangeWish;
  final String? reviewReason;
  final String sellerType;
  final bool isFavorite;

  /// Bản sửa đang chờ duyệt / bị từ chối của tin đã duyệt (chỉ chủ tin thấy)
  final ListingRevisionModel? pendingEdit;

  const ListingModel({
    required this.id,
    this.shortId,
    required this.ownerId,
    required this.title,
    required this.description,
    this.price,
    bool isPartner = false,
    this.shopId,
    this.condition,
    this.status = ListingStatus.available,
    this.allowSale = true,
    this.allowExchange = false,
    this.isFree = false,
    this.isNegotiable = true,
    this.multipleUnits = false,
    this.meetUp = true,
    this.images = const [],
    this.viewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.paidCredits = 0,
    this.startsAt,
    this.displayDays,
    this.autoExtend = false,
    this.categoryId,
    this.subcategoryId,
    this.categoryName = '',
    this.attributes = const {},
    this.provinceCode,
    this.wardCode,
    this.geoPoint,
    this.address,
    this.sellerName = '',
    this.sellerAvatarUrl,
    this.sellerRating,
    this.sellerSoldCount,
    this.shopSummary,
    this.exchangeWish = '',
    this.reviewReason,
    this.sellerType = 'PERSONAL',
    this.isFavorite = false,
    this.pendingEdit,
  }) : _isPartner = isPartner;

  String? get coverImage => images.isEmpty ? null : images.first;

  static int? _parseMoney(Object? value) =>
      value is num ? value.toInt() : num.tryParse('$value')?.toInt();

  factory ListingModel.fromJson(
    Map<String, dynamic> json, {
    String? apiBaseUrl,
  }) {
    final location = json['location'];
    final owner = json['owner'] as Map?;
    return ListingModel(
      id: '${json['id']}',
      shortId: (json['shortId'] as num?)?.toInt(),
      ownerId: '${json['ownerId'] ?? ''}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _parseMoney(json['price']),
      isPartner: json['isPartner'] == true,
      shopId: json['shopId'] as String?,
      condition: ListingCondition.fromApi(json['condition'] as String?),
      status:
          ListingStatus.fromApi(json['status'] as String?) ??
          ListingStatus.available,
      allowSale: json['allowSale'] as bool? ?? true,
      allowExchange: json['allowExchange'] as bool? ?? false,
      isFree: json['isFree'] == true,
      isNegotiable: json['isNegotiable'] as bool? ?? true,
      multipleUnits: json['multipleUnits'] == true,
      meetUp: json['meetUp'] as bool? ?? true,
      images: [
        for (final image in json['images'] as List? ?? const [])
          '$image'.startsWith('/api/')
              ? '${Uri.parse(apiBaseUrl ?? AppEnvironment.apiBaseUrl).origin}$image'
              : '$image',
      ],
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      expiresAt: DateTime.tryParse('${json['expiresAt']}'),
      paidCredits: (json['paidCredits'] as num?)?.toInt() ?? 0,
      startsAt: DateTime.tryParse('${json['startsAt']}'),
      displayDays: (json['displayDays'] as num?)?.toInt(),
      autoExtend: json['autoExtend'] == true,
      categoryId: json['categoryId'] as String?,
      subcategoryId: json['subcategoryId'] as String?,
      // Tên danh mục từ API là chuỗi hoặc map theo ngôn ngữ {vi, en}
      categoryName: LocalizedText.fromJson(
        (json['category'] as Map?)?['name'],
      ).resolve(PlatformDispatcher.instance.locale.languageCode),
      attributes: Map<String, Object?>.from(json['attributes'] as Map? ?? {}),
      provinceCode: location is Map
          ? location['provinceCode'] as String?
          : null,
      wardCode: location is Map ? location['wardCode'] as String? : null,
      geoPoint: location is Map && location['latitude'] != null
          ? GeoPoint.fromJson(Map<String, dynamic>.from(location))
          : null,
      address:
          location is Map &&
              location['province'] is Map &&
              location['ward'] is Map
          ? AddressInfo.fromJson({
              ...Map<String, dynamic>.from(location),
              'geoPoint': location['latitude'] == null
                  ? null
                  : {
                      'latitude': location['latitude'],
                      'longitude': location['longitude'],
                    },
              'isGeoPointFromDevice': location['geoSource'] == 'device',
            })
          : null,
      shopSummary: json['shopSummary'] is Map
          ? ShopModel.fromJson(
              Map<String, dynamic>.from(json['shopSummary'] as Map),
            )
          : null,
      sellerName: owner?['fullName'] as String? ?? '',
      sellerAvatarUrl: owner?['avatarUrl'] as String?,
      sellerRating: ((owner?['ratingCount'] as num?) ?? 0) > 0
          ? (owner?['ratingAverage'] as num?)?.toDouble()
          : null,
      sellerSoldCount: (owner?['soldCount'] as num?)?.toInt(),
      exchangeWish: json['exchangeWish'] as String? ?? '',
      reviewReason: json['reviewReason'] as String?,
      sellerType: json['sellerType'] as String? ?? 'PERSONAL',
      isFavorite: json['isFavorite'] == true,
      pendingEdit: ListingRevisionModel.fromListingJson(
        json,
        json['pendingEdit'],
        apiBaseUrl: apiBaseUrl,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    shortId,
    ownerId,
    title,
    description,
    price,
    isPartner,
    shopId,
    condition,
    status,
    allowSale,
    allowExchange,
    isFree,
    isNegotiable,
    multipleUnits,
    meetUp,
    images,
    viewCount,
    createdAt,
    updatedAt,
    expiresAt,
    paidCredits,
    startsAt,
    displayDays,
    autoExtend,
    categoryId,
    subcategoryId,
    categoryName,
    attributes,
    provinceCode,
    wardCode,
    geoPoint,
    address,
    sellerName,
    sellerAvatarUrl,
    sellerRating,
    sellerSoldCount,
    shopSummary,
    exchangeWish,
    reviewReason,
    sellerType,
    isFavorite,
    pendingEdit,
  ];
}
