import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show setEquals;
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

/// Nhóm tình trạng trong bộ lọc: Điện tử có thêm "Còn bảo hành"
/// (thuộc tính warranty), nhóm khác chỉ Mới / Đã sử dụng.
enum ListingConditionGroup {
  warranty,
  newItem,
  used;

  /// Các nhóm có trong bộ lọc: "Còn bảo hành" chỉ khi danh mục có bảo hành
  static List<ListingConditionGroup> available({bool warranty = false}) => [
    if (warranty) ListingConditionGroup.warranty,
    newItem,
    used,
  ];

  /// Các tình trạng chi tiết của app ứng với nhóm (bảo hành lọc theo thuộc tính)
  Set<ListingCondition> get conditions => switch (this) {
    warranty => const {},
    newItem => const {ListingCondition.newItem},
    used => const {
      ListingCondition.likeNew,
      ListingCondition.usedGood,
      ListingCondition.usedFair,
      ListingCondition.forParts,
    },
  };
}

/// "Đăng bởi": Cá nhân (không gói), Bán chuyên (gói Bán chuyên),
/// Đối tác (gói Cửa hàng Pro)
enum ListingSellerKind {
  personal('personal'),
  pro('pro'),
  partner('partner');

  const ListingSellerKind(this.apiValue);

  final String apiValue;
}

/// Bộ lọc theo một thuộc tính của danh mục con: [values] cho
/// thuộc tính chọn (Hãng, Dung lượng...), [min]/[max] cho thuộc tính số
/// (Năm sản xuất, Số km...).
class AttributeFilterValue extends Equatable {
  final Set<String> values;
  final num? min;
  final num? max;

  const AttributeFilterValue({this.values = const {}, this.min, this.max});

  bool get isEmpty => values.isEmpty && min == null && max == null;

  /// Giá trị gửi trong query attrs: danh sách giá trị hoặc {min, max}
  Object toJson() =>
      values.isNotEmpty ? values.toList() : {'min': ?min, 'max': ?max};

  @override
  List<Object?> get props => [values, min, max];
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

  /// Danh mục con trong [categoryId] (null là mọi danh mục con)
  final String? subcategoryId;

  /// Bộ lọc thuộc tính của danh mục con, theo key thuộc tính
  final Map<String, AttributeFilterValue> attributeFilters;

  /// Khoảng giá VND, mỗi đầu null là không giới hạn
  final int? minPrice;
  final int? maxPrice;

  /// Rỗng là mọi tình trạng; chọn nhiều thì khớp một trong số đó
  final Set<ListingCondition> conditions;

  /// "Đăng bởi": rỗng là mọi người đăng
  final Set<ListingSellerKind> sellers;

  const ListingFilter({
    this.dealTypes = const {},
    this.sort = ListingSort.newest,
    this.radiusKm,
    this.categoryId,
    this.subcategoryId,
    this.attributeFilters = const {},
    this.minPrice,
    this.maxPrice,
    this.conditions = const {},
    this.sellers = const {},
  });

  /// Thuộc tính bảo hành và các giá trị tính là "Còn bảo hành"
  static const warrantyKey = 'warranty';
  static const warrantyValues = {'manufacturer', 'store'};

  /// Nhóm tình trạng đang chọn (suy ra từ tình trạng chi tiết và thuộc tính
  /// bảo hành), null là chưa chọn hoặc là tổ hợp khác
  ListingConditionGroup? get conditionGroup {
    final warranty = attributeFilters[warrantyKey]?.values;
    if (warranty != null) {
      return conditions.isEmpty && setEquals(warranty, warrantyValues)
          ? ListingConditionGroup.warranty
          : null;
    }
    for (final group in ListingConditionGroup.values) {
      if (group.conditions.isNotEmpty &&
          setEquals(conditions, group.conditions)) {
        return group;
      }
    }
    return null;
  }

  /// Chọn một nhóm tình trạng (null là bỏ lọc tình trạng)
  ListingFilter withConditionGroup(ListingConditionGroup? group) {
    final attributes = {
      for (final entry in attributeFilters.entries)
        if (entry.key != warrantyKey) entry.key: entry.value,
      if (group == ListingConditionGroup.warranty)
        warrantyKey: const AttributeFilterValue(values: warrantyValues),
    };
    return copyWith(
      conditions: group?.conditions ?? const {},
      attributeFilters: attributes,
    );
  }

  ListingFilter toggleSeller(ListingSellerKind kind) =>
      copyWith(sellers: _toggle(sellers, kind));

  bool get hasPriceRange => minPrice != null || maxPrice != null;

  /// Số tiêu chí đang bật so với bộ lọc mặc định [defaults] của trang
  /// (danh mục, danh mục con, từng thuộc tính, khoảng giá, tình trạng, kiểu
  /// giao dịch, bán kính), hiện trên nút "Bộ lọc" và trong sheet. Sắp xếp có
  /// chip riêng nên không tính.
  int activeCount([ListingFilter defaults = const ListingFilter()]) =>
      (categoryId == defaults.categoryId ? 0 : 1) +
      (subcategoryId == defaults.subcategoryId ? 0 : 1) +
      attributeFilters.length +
      (hasPriceRange ? 1 : 0) +
      (conditions.isEmpty ? 0 : 1) +
      (sellers.isEmpty ? 0 : 1) +
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
    String? Function()? subcategoryId,
    Map<String, AttributeFilterValue>? attributeFilters,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    Set<ListingCondition>? conditions,
    Set<ListingSellerKind>? sellers,
  }) => ListingFilter(
    dealTypes: dealTypes ?? this.dealTypes,
    sort: sort ?? this.sort,
    radiusKm: radiusKm ?? this.radiusKm,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    subcategoryId: subcategoryId == null ? this.subcategoryId : subcategoryId(),
    attributeFilters: attributeFilters ?? this.attributeFilters,
    minPrice: minPrice == null ? this.minPrice : minPrice(),
    maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
    conditions: conditions ?? this.conditions,
    sellers: sellers ?? this.sellers,
  );

  /// Đổi danh mục: bỏ danh mục con, bộ lọc thuộc tính và nhóm tình trạng
  /// của danh mục cũ (mỗi danh mục có nhóm tình trạng riêng)
  ListingFilter withCategory(String? id) => id == categoryId
      ? this
      : copyWith(
          categoryId: () => id,
          subcategoryId: () => null,
          attributeFilters: const {},
          conditions: const {},
        );

  /// Đổi danh mục con: bộ lọc thuộc tính khác nhau theo danh mục con nên bỏ
  /// (giữ "Còn bảo hành" vì thuộc nhóm tình trạng)
  ListingFilter withSubcategory(String? id) => id == subcategoryId
      ? this
      : copyWith(
          subcategoryId: () => id,
          attributeFilters: {
            if (attributeFilters[warrantyKey] case final warranty?)
              warrantyKey: warranty,
          },
        );

  /// Chọn đúng một giá trị của thuộc tính (chip chọn một / danh sách); chọn
  /// lại giá trị đang chọn hoặc null thì bỏ lọc thuộc tính đó
  ListingFilter selectAttributeValue(String key, String? value) {
    final current = attributeFilters[key]?.values ?? const <String>{};
    final clear =
        value == null || (current.length == 1 && current.contains(value));
    return withAttribute(
      key,
      clear
          ? const AttributeFilterValue()
          : AttributeFilterValue(values: {value}),
    );
  }

  /// Đặt bộ lọc của một thuộc tính; giá trị rỗng thì bỏ thuộc tính đó
  ListingFilter withAttribute(String key, AttributeFilterValue value) =>
      copyWith(
        attributeFilters: {
          for (final entry in attributeFilters.entries)
            if (entry.key != key) entry.key: entry.value,
          if (!value.isEmpty) key: value,
        },
      );

  /// Bật / tắt một giá trị của thuộc tính chọn
  ListingFilter toggleAttributeValue(String key, String value) {
    final current = attributeFilters[key]?.values ?? const <String>{};
    return withAttribute(
      key,
      AttributeFilterValue(values: _toggle(current, value)),
    );
  }

  /// Bật / tắt một kiểu giao dịch
  ListingFilter toggleDeal(ListingDealType type) =>
      copyWith(dealTypes: _toggle(dealTypes, type));

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
    if (categoryId != null) 'subcategoryId': ?subcategoryId,
    if (categoryId != null && attributeFilters.isNotEmpty)
      'attrs': jsonEncode({
        for (final entry in attributeFilters.entries)
          entry.key: entry.value.toJson(),
      }),
    'minPrice': ?minPrice,
    'maxPrice': ?maxPrice,
    if (conditions.isNotEmpty)
      'condition': [for (final item in conditions) item.apiValue].join(','),
    if (sellers.isNotEmpty)
      'seller': [for (final item in sellers) item.apiValue].join(','),
  };

  @override
  List<Object?> get props => [
    dealTypes,
    sort,
    radiusKm,
    categoryId,
    subcategoryId,
    attributeFilters,
    minPrice,
    maxPrice,
    conditions,
    sellers,
  ];
}
