import 'package:flutter_test/flutter_test.dart';
import 'package:restore/shared/models/listing_filter.dart';

void main() {
  test('area goes to the API and survives the sheet reset', () {
    const defaults = ListingFilter(categoryId: 'phones');
    final filter = defaults.copyWith(
      provinceCode: () => '79',
      sort: ListingSort.priceLow,
      minPrice: () => 100000,
    );

    expect(filter.toQuery(), containsPair('provinceCode', '79'));
    expect(filter.toQuery(), containsPair('sort', 'price_asc'));
    expect(filter.toQuery().containsKey('wardCode'), isFalse);
    // Khu vực có chip riêng nên không tính vào số tiêu chí của nút Bộ lọc
    expect(filter.activeCount(defaults), 1);

    final reset = filter.resetTo(defaults);
    expect(reset.minPrice, isNull);
    expect(reset.provinceCode, '79');
    expect(reset.sort, ListingSort.priceLow);
  });
}
