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

  /// Khu vực của tin: mã tỉnh/thành hoặc mã phường/xã (chọn một trong hai),
  /// null là toàn quốc. Trang tự hiện chip khu vực nên không tính vào
  /// [activeCount] và giữ nguyên khi "Xoá bộ lọc" trong sheet.
  final String? provinceCode;
  final String? wardCode;

  /// Tên khu vực đang lọc để hiện trên chip, không gửi lên API
  final String? areaLabel;

  /// Thuộc tính dạng chọn của danh mục (key → các giá trị đã chọn), gửi lên
  /// API dạng `attr.<key>=a,b`. Đổi danh mục thì phải xoá vì key theo danh mục.
  final Map<String, Set<String>> attributes;

  /// Thuộc tính dạng số (key → khoảng, mỗi đầu null là không giới hạn), gửi
  /// lên API dạng `attrMin.<key>` / `attrMax.<key>`
  final Map<String, ({int? min, int? max})> attributeRanges;

  const ListingFilter({
    this.dealTypes = const {},
    this.sort = ListingSort.newest,
    this.radiusKm,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.conditions = const {},
    this.provinceCode,
    this.wardCode,
    this.areaLabel,
    this.attributes = const {},
    this.attributeRanges = const {},
  });

  bool get hasArea => provinceCode != null || wardCode != null;

  bool get hasPriceRange => minPrice != null || maxPrice != null;

  /// Số tiêu chí đang bật so với bộ lọc mặc định [defaults] của trang
  /// (danh mục, khoảng giá, tình trạng, kiểu giao dịch, bán kính, mỗi thuộc tính), hiện trên
  /// nút "Bộ lọc" và trong sheet. Sắp xếp có chip riêng nên không tính.
  int activeCount([ListingFilter defaults = const ListingFilter()]) =>
      (categoryId == defaults.categoryId ? 0 : 1) +
      (hasPriceRange ? 1 : 0) +
      (conditions.isEmpty ? 0 : 1) +
      (dealTypes.isEmpty ? 0 : 1) +
      (radiusKm == defaults.radiusKm ? 0 : 1) +
      attributes.length +
      attributeRanges.length;

  /// Xoá mọi tiêu chí về [defaults] nhưng giữ cách sắp xếp và khu vực đang chọn
  ListingFilter resetTo(ListingFilter defaults) => defaults.copyWith(
    sort: sort,
    provinceCode: () => provinceCode,
    wardCode: () => wardCode,
    areaLabel: () => areaLabel,
  );

  /// Lọc theo một tỉnh/thành hoặc phường/xã ([isWard]), [code] null là toàn quốc
  ListingFilter withArea(String? code, {bool isWard = false, String? label}) =>
      copyWith(
        provinceCode: () => code == null || isWard ? null : code,
        wardCode: () => code != null && isWard ? code : null,
        areaLabel: () => code == null ? null : label,
      );

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
    String? Function()? provinceCode,
    String? Function()? wardCode,
    String? Function()? areaLabel,
    Map<String, Set<String>>? attributes,
    Map<String, ({int? min, int? max})>? attributeRanges,
  }) => ListingFilter(
    dealTypes: dealTypes ?? this.dealTypes,
    sort: sort ?? this.sort,
    radiusKm: radiusKm ?? this.radiusKm,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    minPrice: minPrice == null ? this.minPrice : minPrice(),
    maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
    conditions: conditions ?? this.conditions,
    provinceCode: provinceCode == null ? this.provinceCode : provinceCode(),
    wardCode: wardCode == null ? this.wardCode : wardCode(),
    areaLabel: areaLabel == null ? this.areaLabel : areaLabel(),
    attributes: attributes ?? this.attributes,
    attributeRanges: attributeRanges ?? this.attributeRanges,
  );

  /// Bật / tắt một kiểu giao dịch
  ListingFilter toggleDeal(ListingDealType type) =>
      copyWith(dealTypes: _toggle(dealTypes, type));

  /// Bật / tắt một tình trạng sản phẩm
  ListingFilter toggleCondition(ListingCondition condition) =>
      copyWith(conditions: _toggle(conditions, condition));

  /// Bật / tắt một giá trị của thuộc tính [key]; bỏ hết thì xoá luôn key
  ListingFilter toggleAttribute(String key, String value) {
    final values = _toggle(attributes[key] ?? const <String>{}, value);
    return copyWith(
      attributes: {
        for (final entry in attributes.entries)
          if (entry.key != key) entry.key: entry.value,
        if (values.isNotEmpty) key: values,
      },
    );
  }

  /// Đặt khoảng cho thuộc tính số [key]; cả hai đầu null thì bỏ lọc
  ListingFilter setAttributeRange(String key, {int? min, int? max}) => copyWith(
    attributeRanges: {
      for (final entry in attributeRanges.entries)
        if (entry.key != key) entry.key: entry.value,
      if (min != null || max != null) key: (min: min, max: max),
    },
  );

  /// Có khoảng thuộc tính nào đang để đầu dưới lớn hơn đầu trên
  bool get hasInvalidAttributeRange => attributeRanges.values.any(
    (range) =>
        range.min != null && range.max != null && range.min! > range.max!,
  );

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
    'provinceCode': ?provinceCode,
    'wardCode': ?wardCode,
    for (final entry in attributes.entries)
      'attr.${entry.key}': entry.value.join(','),
    for (final entry in attributeRanges.entries) ...{
      'attrMin.${entry.key}': ?entry.value.min,
      'attrMax.${entry.key}': ?entry.value.max,
    },
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
    provinceCode,
    wardCode,
    areaLabel,
    attributes,
    attributeRanges,
  ];
}
