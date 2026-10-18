import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Một dòng của bảng Listing (prisma/schema.prisma), tên khoá JSON giống
/// tên cột (camelCase).
///
/// Các trường đánh dấu "(đề xuất)" chưa có trong schema hiện tại; chúng theo
/// docs/listing-api-contract.md và để null cho tới khi backend thêm cột.
class ListingModel extends Equatable {
  final String id;
  final String ownerId;
  final String title;
  final String description;

  /// Giá VND. Cột Decimal nên API có thể trả về chuỗi hoặc số.
  final int? price;
  final bool isNegotiable;
  final ListingCondition? condition;
  final ListingStatus status;
  final bool allowSale;
  final bool allowExchange;
  final List<String> images;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// (đề xuất) Danh mục và thuộc tính theo danh mục (jsonb)
  final String? categoryId;
  final Map<String, Object?> attributes;

  /// (đề xuất) Mã tỉnh/thành, phường/xã và toạ độ cho tính năng "gần bạn"
  final String? provinceCode;
  final String? wardCode;
  final GeoPoint? geoPoint;

  const ListingModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.price,
    this.isNegotiable = true,
    this.condition,
    this.status = ListingStatus.available,
    this.allowSale = true,
    this.allowExchange = false,
    this.images = const [],
    this.viewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.categoryId,
    this.attributes = const {},
    this.provinceCode,
    this.wardCode,
    this.geoPoint,
  });

  String? get coverImage => images.isEmpty ? null : images.first;

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    final location = json['location'];
    return ListingModel(
      id: '${json['id']}',
      ownerId: '${json['ownerId'] ?? ''}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: price is num ? price.toInt() : num.tryParse('$price')?.toInt(),
      isNegotiable: json['isNegotiable'] as bool? ?? true,
      condition: ListingCondition.fromApi(json['condition'] as String?),
      status:
          ListingStatus.fromApi(json['status'] as String?) ??
          ListingStatus.available,
      allowSale: json['allowSale'] as bool? ?? true,
      allowExchange: json['allowExchange'] as bool? ?? false,
      images: [
        for (final image in json['images'] as List? ?? const []) '$image',
      ],
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      categoryId: json['categoryId'] as String?,
      attributes: Map<String, Object?>.from(json['attributes'] as Map? ?? {}),
      provinceCode: location is Map
          ? location['provinceCode'] as String?
          : null,
      wardCode: location is Map ? location['wardCode'] as String? : null,
      geoPoint: location is Map && location['latitude'] != null
          ? GeoPoint.fromJson(Map<String, dynamic>.from(location))
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    title,
    description,
    price,
    isNegotiable,
    condition,
    status,
    allowSale,
    allowExchange,
    images,
    viewCount,
    createdAt,
    updatedAt,
    categoryId,
    attributes,
    provinceCode,
    wardCode,
    geoPoint,
  ];
}
