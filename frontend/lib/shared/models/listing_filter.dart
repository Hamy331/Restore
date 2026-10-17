import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/listing_condition.dart';

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
/// danh mục...). Hàng lọc nhanh và sheet Bộ lọc đầy đủ cùng chỉnh object này.
class ListingFilter extends Equatable {
  /// Rỗng là không lọc; chọn nhiều thì tin khớp một trong các kiểu là được
  final Set<ListingDealType> dealTypes;
  final ListingSort sort;

  /// Bán kính tìm quanh vị trí (km), null là không giới hạn
  final double? radiusKm;
  final String? categoryId;

  /// Khoảng giá VND, mỗi đầu null là không giới hạn
  final int? minPrice;
  final int? maxPrice;

  /// Rỗng là mọi tình trạng; chọn nhiều thì khớp một trong số đó
  final Set<ListingCondition> conditions;

  const ListingFilter({
    this.dealTypes = const {},
    this.sort = ListingSort.newest,
    this.radiusKm,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.conditions = const {},
  });

  bool get hasPriceRange => minPrice != null || maxPrice != null;

  /// Số tiêu chí đang bật so với bộ lọc mặc định [defaults] của trang
  /// (danh mục, khoảng giá, tình trạng, kiểu giao dịch, bán kính), hiện trên
  /// nút "Bộ lọc" và trong sheet. Sắp xếp có chip riêng nên không tính.
  int activeCount([ListingFilter defaults = const ListingFilter()]) =>
      (categoryId == defaults.categoryId ? 0 : 1) +
      (hasPriceRange ? 1 : 0) +
      (conditions.isEmpty ? 0 : 1) +
      (dealTypes.isEmpty ? 0 : 1) +
      (radiusKm == defaults.radiusKm ? 0 : 1);

  /// Xoá mọi tiêu chí về [defaults] nhưng giữ cách sắp xếp đang chọn
  ListingFilter resetTo(ListingFilter defaults) =>
      defaults.copyWith(sort: sort);

  /// Các trường có thể null nhận hàm trả giá trị để xoá được về null,
  /// VD `copyWith(categoryId: () => null)`.
  ListingFilter copyWith({
    Set<ListingDealType>? dealTypes,
    ListingSort? sort,
    double? radiusKm,
    String? Function()? categoryId,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    Set<ListingCondition>? conditions,
  }) => ListingFilter(
    dealTypes: dealTypes ?? this.dealTypes,
    sort: sort ?? this.sort,
    radiusKm: radiusKm ?? this.radiusKm,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    minPrice: minPrice == null ? this.minPrice : minPrice(),
    maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
    conditions: conditions ?? this.conditions,
  );

  /// Bật / tắt một kiểu giao dịch
  ListingFilter toggleDeal(ListingDealType type) =>
      copyWith(dealTypes: _toggle(dealTypes, type));

  /// Bật / tắt một tình trạng sản phẩm
  ListingFilter toggleCondition(ListingCondition condition) =>
      copyWith(conditions: _toggle(conditions, condition));

  static Set<T> _toggle<T>(Set<T> values, T value) => values.contains(value)
      ? ({...values}..remove(value))
      : {...values, value};

  /// Query gửi API, bỏ các tiêu chí đang để trống
  Map<String, dynamic> toQuery() => {
    if (dealTypes.isNotEmpty)
      'deal': [for (final type in dealTypes) type.apiValue].join(','),
    'sort': sort.apiValue,
    'radiusKm': ?radiusKm,
    'categoryId': ?categoryId,
    'minPrice': ?minPrice,
    'maxPrice': ?maxPrice,
    if (conditions.isNotEmpty)
      'condition': [for (final item in conditions) item.apiValue].join(','),
  };

  @override
  List<Object?> get props => [
    dealTypes,
    sort,
    radiusKm,
    categoryId,
    minPrice,
    maxPrice,
    conditions,
  ];
}
