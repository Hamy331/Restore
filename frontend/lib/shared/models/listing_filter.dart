import 'package:equatable/equatable.dart';

/// Cách người mua muốn nhận món đồ, khớp cột allowSale / allowExchange
/// của bảng Listing. [apiValue] gửi lên query `deal=buy,exchange`.
enum ListingDealType {
  /// Mua trực tiếp bằng tiền (allowSale)
  buy('buy'),

  /// Đổi đồ lấy đồ (allowExchange)
  exchange('exchange');

  const ListingDealType(this.apiValue);

  final String apiValue;
}

/// Thứ tự sắp xếp danh sách tin. [nearest] chỉ dùng khi đã biết vị trí,
/// [relevance] chỉ dùng khi có từ khoá tìm kiếm.
enum ListingSort {
  relevance('relevance'),
  nearest('nearest'),
  newest('newest'),
  priceLow('price_asc'),
  priceHigh('price_desc');

  const ListingSort(this.apiValue);

  final String apiValue;
}

/// Bộ lọc tin đăng dùng chung cho các trang danh sách (gần bạn, tìm kiếm,
/// danh mục...). Mỗi trang chỉ hiện những tiêu chí nó cần; trang Bộ lọc
/// đầy đủ chỉnh trên cùng một object này.
class ListingFilter extends Equatable {
  /// Rỗng là không lọc; chọn nhiều thì tin khớp một trong các kiểu là được
  final Set<ListingDealType> dealTypes;
  final ListingSort sort;

  /// Bán kính tìm quanh vị trí (km), null là không giới hạn
  final double? radiusKm;
  final String? categoryId;
  final int? minPrice;
  final int? maxPrice;

  const ListingFilter({
    this.dealTypes = const {},
    this.sort = ListingSort.newest,
    this.radiusKm,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
  });

  /// Số tiêu chí đang bật ở trang Bộ lọc đầy đủ (danh mục, khoảng giá),
  /// để hiện số trên nút "Bộ lọc". Kiểu giao dịch, bán kính và sắp xếp đã
  /// có chip riêng nên không tính.
  int get advancedCount =>
      (categoryId == null ? 0 : 1) +
      (minPrice == null && maxPrice == null ? 0 : 1);

  ListingFilter copyWith({
    Set<ListingDealType>? dealTypes,
    ListingSort? sort,
    double? radiusKm,
  }) => ListingFilter(
    dealTypes: dealTypes ?? this.dealTypes,
    sort: sort ?? this.sort,
    radiusKm: radiusKm ?? this.radiusKm,
    categoryId: categoryId,
    minPrice: minPrice,
    maxPrice: maxPrice,
  );

  /// Bật / tắt một kiểu giao dịch
  ListingFilter toggleDeal(ListingDealType type) => copyWith(
    dealTypes: dealTypes.contains(type)
        ? ({...dealTypes}..remove(type))
        : {...dealTypes, type},
  );

  /// Query gửi API, bỏ các tiêu chí đang để trống
  Map<String, dynamic> toQuery() => {
    if (dealTypes.isNotEmpty)
      'deal': [for (final type in dealTypes) type.apiValue].join(','),
    'sort': sort.apiValue,
    'radiusKm': ?radiusKm,
    'categoryId': ?categoryId,
    'minPrice': ?minPrice,
    'maxPrice': ?maxPrice,
  };

  @override
  List<Object?> get props => [
    dealTypes,
    sort,
    radiusKm,
    categoryId,
    minPrice,
    maxPrice,
  ];
}
