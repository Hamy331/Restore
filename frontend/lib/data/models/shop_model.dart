import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/shop_verification_type.dart';

/// Một dòng của bảng Shop (đề xuất, xem `backend/docs/trusted-shops.md`):
/// gian hàng của một tài khoản bán, chỉ hiện ở "Shop uy tín" khi đã được
/// xác minh. Tên khoá JSON giống tên cột (camelCase).
class ShopModel extends Equatable {
  final String id;

  /// Tài khoản (User) quản lý shop
  final String ownerId;
  final String name;

  /// Câu giới thiệu ngắn hiện trên thẻ shop
  final String tagline;
  final String description;

  /// Ảnh logo / ảnh bìa: URL từ API, null thì app vẽ logo chữ và nền màu
  final String? logoUrl;
  final String? coverUrl;

  /// Màu nhận diện dạng hex (VD "#2B63C6") cho logo chữ và nền bìa
  final String? accentColor;

  /// null là shop chưa được xác minh (không hiện ở Shop uy tín)
  final ShopVerificationType? verificationType;
  final DateTime? verifiedAt;

  /// Mã chứng nhận ReStore cấp, VD "RS-2026-00128"
  final String? certificateCode;

  /// Danh mục shop bán (Category.id)
  final List<String> categoryIds;

  /// Địa chỉ hiển thị, VD "Quận 1, TP. Hồ Chí Minh"
  final String? address;
  final double ratingAverage;
  final int ratingCount;
  final int followerCount;

  /// Số tin đang bán (AVAILABLE)
  final int listingCount;
  final DateTime? createdAt;

  const ShopModel({
    required this.id,
    required this.name,
    this.ownerId = '',
    this.tagline = '',
    this.description = '',
    this.logoUrl,
    this.coverUrl,
    this.accentColor,
    this.verificationType,
    this.verifiedAt,
    this.certificateCode,
    this.categoryIds = const [],
    this.address,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.followerCount = 0,
    this.listingCount = 0,
    this.createdAt,
  });

  bool get isVerified => verificationType != null;

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
    id: '${json['id']}',
    ownerId: '${json['ownerId'] ?? ''}',
    name: json['name'] as String? ?? '',
    tagline: json['tagline'] as String? ?? '',
    description: json['description'] as String? ?? '',
    logoUrl: json['logoUrl'] as String?,
    coverUrl: json['coverUrl'] as String?,
    accentColor: json['accentColor'] as String?,
    verificationType: ShopVerificationType.fromApi(
      json['verificationType'] as String?,
    ),
    verifiedAt: DateTime.tryParse('${json['verifiedAt']}'),
    certificateCode: json['certificateCode'] as String?,
    categoryIds: [
      for (final id in json['categoryIds'] as List? ?? const []) '$id',
    ],
    address: json['address'] as String?,
    ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
    ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse('${json['createdAt']}'),
  );

  ShopModel copyWith({int? followerCount}) => ShopModel(
    id: id,
    ownerId: ownerId,
    name: name,
    tagline: tagline,
    description: description,
    logoUrl: logoUrl,
    coverUrl: coverUrl,
    accentColor: accentColor,
    verificationType: verificationType,
    verifiedAt: verifiedAt,
    certificateCode: certificateCode,
    categoryIds: categoryIds,
    address: address,
    ratingAverage: ratingAverage,
    ratingCount: ratingCount,
    followerCount: followerCount ?? this.followerCount,
    listingCount: listingCount,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    tagline,
    description,
    logoUrl,
    coverUrl,
    accentColor,
    verificationType,
    verifiedAt,
    certificateCode,
    categoryIds,
    address,
    ratingAverage,
    ratingCount,
    followerCount,
    listingCount,
    createdAt,
  ];
}
