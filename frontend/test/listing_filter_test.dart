import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
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

  test('attributes go to the API as attr.<key> and count per key', () {
    const defaults = ListingFilter(categoryId: 'phones');
    final filter = defaults
        .toggleAttribute('brand', 'Apple')
        .toggleAttribute('brand', 'Samsung')
        .toggleAttribute('storage', '128 GB')
        .toggleAttribute('storage', '128 GB');
    expect(filter.toQuery(), containsPair('attr.brand', 'Apple,Samsung'));
    expect(filter.toQuery().containsKey('attr.storage'), isFalse);
    expect(filter.activeCount(defaults), 1);
    expect(filter.resetTo(defaults).attributes, isEmpty);
  });

  test('number ranges go to the API as attrMin/attrMax', () {
    const defaults = ListingFilter(categoryId: 'vehicles');
    final filter = defaults
        .setAttributeRange('year', min: 2018)
        .setAttributeRange('mileage', max: 50000);
    expect(filter.toQuery(), containsPair('attrMin.year', 2018));
    expect(filter.toQuery().containsKey('attrMax.year'), isFalse);
    expect(filter.toQuery(), containsPair('attrMax.mileage', 50000));
    expect(filter.activeCount(defaults), 2);
    expect(filter.hasInvalidAttributeRange, isFalse);
    expect(
      filter
          .setAttributeRange('year', min: 2020, max: 2010)
          .hasInvalidAttributeRange,
      isTrue,
    );
    expect(filter.setAttributeRange('year').attributeRanges.keys, ['mileage']);
  });

  testWidgets('sheet filters by yes/no and number attributes', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    ListingFilter? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showListingFilterSheet(
              context,
              filter: const ListingFilter(categoryId: 'vehicles'),
              defaults: const ListingFilter(categoryId: 'vehicles'),
              showCategories: false,
              repository: MockListingFilterOptionsRepository(
                latency: Duration.zero,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Loại xe'), findsOneWidget);
    // Thuộc tính chữ tự do không có nhóm lọc
    expect(find.text('Dòng xe'), findsNothing);
    await tester.enterText(
      find
          .descendant(
            of: find.byKey(const ValueKey('range-year')),
            matching: find.byType(TextField),
          )
          .first,
      '2018',
    );
    await tester.tap(find.text('Có'));
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryActionButton));
    await tester.pumpAndSettle();

    expect(result?.attributeRanges['year'], (min: 2018, max: null));
    expect(result?.attributes['has_papers'], {'true'});
  });

  test('changing category in the sheet drops its attributes', () {
    final cubit = ListingFilterCubit(
      repository: MockListingFilterOptionsRepository(latency: Duration.zero),
      initial: const ListingFilter(categoryId: 'phones'),
      defaults: const ListingFilter(),
    );
    cubit.toggleAttribute('brand', 'Apple');
    cubit.setAttributeRange('battery_health', min: 80);
    cubit.selectCategory('phones');
    expect(cubit.state.draft.attributes, isNotEmpty);
    cubit.selectCategory('laptops');
    expect(cubit.state.draft.attributes, isEmpty);
    expect(cubit.state.draft.attributeRanges, isEmpty);
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
