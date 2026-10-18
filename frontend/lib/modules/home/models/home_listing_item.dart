import 'package:equatable/equatable.dart';
import 'package:restore/data/models/listing_model.dart';

/// Tin đăng kèm thông tin hiển thị trên thẻ ở trang chủ.
/// API trả về một bản ghi Listing cùng vài trường đã tính sẵn.
class HomeListingItem extends Equatable {
  final ListingModel listing;

  /// Khu vực rút gọn để hiện trên thẻ, VD "Bình Thạnh, TP.HCM"
  final String areaLabel;

  /// Khoảng cách tới người xem (km), null khi chưa biết vị trí
  final double? distanceKm;

  /// Tin được đẩy (boost) nên hiện nhãn "Nổi bật"
  final bool isFeatured;
  final bool isFavorite;

  const HomeListingItem({
    required this.listing,
    required this.areaLabel,
    this.distanceKm,
    this.isFeatured = false,
    this.isFavorite = false,
  });

  factory HomeListingItem.fromJson(Map<String, dynamic> json) =>
      HomeListingItem(
        listing: ListingModel.fromJson(json),
        areaLabel: json['areaLabel'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        isFeatured: json['isFeatured'] as bool? ?? false,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  HomeListingItem copyWith({bool? isFavorite}) => HomeListingItem(
    listing: listing,
    areaLabel: areaLabel,
    distanceKm: distanceKm,
    isFeatured: isFeatured,
    isFavorite: isFavorite ?? this.isFavorite,
  );

  @override
  List<Object?> get props => [
    listing,
    areaLabel,
    distanceKm,
    isFeatured,
    isFavorite,
  ];
}
