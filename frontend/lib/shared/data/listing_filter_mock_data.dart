import 'package:restore/data/models/listing_model.dart';
import 'package:restore/modules/listings/data/listing_mock_data.dart';
import 'package:restore/shared/models/listing_filter.dart';

/// Dữ liệu mẫu cho sheet Bộ lọc, đúng cấu trúc JSON của
/// `GET /listings/filter-options`
class ListingFilterMockData {
  ListingFilterMockData._();

  static Map<String, dynamic> get options => {
    // Bỏ schema thuộc tính, sheet chỉ cần tên và icon danh mục
    'categories': [
      for (final category in ListingMockData.categories)
        {
          'id': category['id'],
          'name': category['name'],
          'description': category['description'],
          'icon': category['icon'],
        },
    ],
    'priceRanges': const [
      {'max': 500000},
      {'min': 500000, 'max': 2000000},
      {'min': 2000000, 'max': 5000000},
      {'min': 5000000},
    ],
  };
}

/// Lọc tin mẫu giống cách backend lọc, dùng chung cho các repository mẫu
/// (Gần bạn, kết quả tìm kiếm...)
extension MockListingFilterMatch on ListingFilter {
  bool matches(ListingModel listing) {
    final dealMatches =
        dealTypes.isEmpty ||
        (dealTypes.contains(ListingDealType.buy) && listing.allowSale) ||
        (dealTypes.contains(ListingDealType.exchange) && listing.allowExchange);
    if (!dealMatches) return false;
    if (categoryId != null && listing.categoryId != categoryId) return false;
    if (subcategoryId != null && listing.subcategoryId != subcategoryId) {
      return false;
    }
    for (final entry in attributeFilters.entries) {
      final value = listing.attributes[entry.key];
      final filter = entry.value;
      if (filter.values.isNotEmpty && !filter.values.contains('$value')) {
        return false;
      }
      if (filter.min != null || filter.max != null) {
        if (value is! num) return false;
        if (filter.min != null && value < filter.min!) return false;
        if (filter.max != null && value > filter.max!) return false;
      }
    }
    if (conditions.isNotEmpty && !conditions.contains(listing.condition)) {
      return false;
    }
    if (hasPriceRange) {
      // Tin chỉ trao đổi không có giá nên không khớp khoảng giá nào
      final price = listing.price;
      if (price == null) return false;
      if (minPrice != null && price < minPrice!) return false;
      if (maxPrice != null && price > maxPrice!) return false;
    }
    return true;
  }
}
