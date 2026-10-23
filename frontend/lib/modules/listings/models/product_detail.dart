import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/data/models/user_model.dart';

/// Dữ liệu trang chi tiết sản phẩm (`GET /listings/:id`): bản ghi Listing
/// kèm người bán, danh mục và vài trường server đã tính sẵn cho người xem.
class ProductDetail extends Equatable {
  final ListingModel listing;
  final UserModel seller;

  /// Danh mục kèm schema thuộc tính để hiển thị "Thông tin chi tiết"
  final CategoryModel? category;

  /// Khu vực công khai (chỉ phường/xã + tỉnh/thành), VD "Phường Võ Thị Sáu, TP.HCM"
  final String areaLabel;

  /// Món người bán muốn đổi lấy (khi tin nhận trao đổi)
  final String? exchangeWish;

  /// Số tin người bán đang hiển thị
  final int sellerActiveListings;

  final bool isFavorite;

  /// Người xem chính là người đăng tin
  final bool isOwner;

  const ProductDetail({
    required this.listing,
    required this.seller,
    required this.areaLabel,
    this.category,
    this.exchangeWish,
    this.sellerActiveListings = 0,
    this.isFavorite = false,
    this.isOwner = false,
  });

  /// Còn mua / trả giá / đổi được không
  bool get isAvailable => listing.status == ListingStatus.available;

  /// Có thể trả giá: tin bán, có giá và người bán cho thương lượng
  bool get canMakeOffer =>
      listing.allowSale && listing.price != null && listing.isNegotiable;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final seller = json['owner'] ?? json['seller'];
    final category = json['category'];
    final wish = (json['exchangeWish'] as String?)?.trim();
    return ProductDetail(
      listing: ListingModel.fromJson(json),
      seller: UserModel.fromJson({
        'email': '',
        ...Map<String, dynamic>.from(seller as Map),
      }),
      category: category is Map
          ? CategoryModel.fromJson(Map<String, dynamic>.from(category))
          : null,
      areaLabel: json['areaLabel'] as String? ?? '',
      exchangeWish: wish == null || wish.isEmpty ? null : wish,
      sellerActiveListings:
          (json['sellerActiveListings'] as num?)?.toInt() ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }

  ProductDetail copyWith({bool? isFavorite}) => ProductDetail(
    listing: listing,
    seller: seller,
    category: category,
    areaLabel: areaLabel,
    exchangeWish: exchangeWish,
    sellerActiveListings: sellerActiveListings,
    isFavorite: isFavorite ?? this.isFavorite,
    isOwner: isOwner,
  );

  @override
  List<Object?> get props => [
    listing,
    seller,
    category,
    areaLabel,
    exchangeWish,
    sellerActiveListings,
    isFavorite,
    isOwner,
  ];
}
