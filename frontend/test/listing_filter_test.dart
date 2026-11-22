import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/category_detail/bloc/category_detail_cubit.dart';
import 'package:restore/modules/category_detail/bloc/category_detail_state.dart';
import 'package:restore/modules/category_detail/repositories/category_listings_repository.dart';
import 'package:restore/modules/listings/data/listing_mock_data.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/models/paged_result.dart';
import 'package:restore/shared/bloc/listing_filter/listing_filter_cubit.dart';
import 'package:restore/shared/repositories/listing_filter_options_repository.dart';

void main() {
  categoryAreaTests();

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

  test('withArea switches between province, ward and nationwide', () {
    const base = ListingFilter();
    final ward = base
        .withArea('79', label: 'Hồ Chí Minh')
        .withArea('26734', isWard: true, label: 'Bến Thành');
    expect(ward.provinceCode, isNull);
    expect(ward.toQuery(), containsPair('wardCode', '26734'));
    expect(ward.areaLabel, 'Bến Thành');
    expect(ward.toQuery().containsKey('areaLabel'), isFalse);

    final nationwide = ward.withArea(null, label: 'ignored');
    expect(nationwide.hasArea, isFalse);
    expect(nationwide.areaLabel, isNull);
  });

  test('attributes go to the API as one attrs JSON and count per key', () {
    const defaults = ListingFilter(categoryId: 'electronics');
    final filter = defaults
        .toggleAttributeValue('brand', 'Apple')
        .toggleAttributeValue('brand', 'Samsung')
        .toggleAttributeValue('storage', '128')
        .toggleAttributeValue('storage', '128');
    expect(jsonDecode(filter.toQuery()['attrs'] as String), {
      'brand': ['Apple', 'Samsung'],
    });
    expect(filter.activeCount(defaults), 1);
    expect(filter.resetTo(defaults).attributeFilters, isEmpty);
  });

  test('number ranges go inside attrs as {min, max}', () {
    const defaults = ListingFilter(categoryId: 'vehicles');
    final filter = defaults
        .withAttribute('year', const AttributeFilterValue(min: 2018))
        .withAttribute('mileage', const AttributeFilterValue(max: 50000));
    expect(jsonDecode(filter.toQuery()['attrs'] as String), {
      'year': {'min': 2018},
      'mileage': {'max': 50000},
    });
    expect(filter.activeCount(defaults), 2);
    expect(
      filter
          .withAttribute('year', const AttributeFilterValue())
          .attributeFilters
          .keys,
      ['mileage'],
    );
  });

  test('changing category in the sheet drops its attributes', () {
    final cubit = ListingFilterCubit(
      repository: MockListingFilterOptionsRepository(latency: Duration.zero),
      initial: const ListingFilter(categoryId: 'electronics'),
      defaults: const ListingFilter(),
    );
    cubit.toggleAttributeValue('brand', 'Apple');
    cubit.setAttributeRange('battery_health', min: 80);
    cubit.selectCategory('electronics');
    expect(cubit.state.draft.attributeFilters, hasLength(2));
    cubit.selectCategory('vehicles');
    expect(cubit.state.draft.attributeFilters, isEmpty);
    cubit.close();
  });
}

class _RecordingRepository extends MockCategoryListingsRepository {
  _RecordingRepository() : super(latency: Duration.zero);

  final queries = <Map<String, dynamic>>[];

  @override
  Future<PagedResult<ListingCardItem>> getListings(
    ListingFilter filter, {
    int page = 1,
  }) {
    queries.add(filter.toQuery());
    return super.getListings(filter, page: page);
  }
}

void categoryAreaTests() {
  test(
    'category page sends its area; clearFilters keeps it, clearAll drops it',
    () async {
      final repository = _RecordingRepository();
      final first = ListingMockData.categories.first['id'] as String;
      final cubit = CategoryDetailCubit(
        repository: repository,
        categoryId: first,
        filter: CategoryDetailState.defaultFilterFor(
          first,
        ).withArea('01', label: 'Hà Nội'),
      );
      await cubit.start();
      expect(repository.queries.last, containsPair('provinceCode', '01'));

      cubit.applyFilter(cubit.state.filter.copyWith(minPrice: () => 1000));
      cubit.clearFilters();
      expect(cubit.state.filter.provinceCode, '01');

      cubit.clearAll();
      expect(cubit.state.filter.hasArea, isFalse);
      await cubit.close();
    },
  );
}
