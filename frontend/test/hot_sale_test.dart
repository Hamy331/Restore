import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/category_detail/bloc/category_detail_cubit.dart';
import 'package:restore/modules/category_detail/repositories/category_listings_repository.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/home/views/home/widgets/home_category_strip.dart';
import 'package:restore/modules/hot_sale/repositories/hot_sale_repository.dart';
import 'package:restore/modules/hot_sale/views/hot_sale/hot_sale_view.dart';
import 'package:restore/modules/listings/data/listing_mock_data.dart';
import 'package:restore/shared/widgets/listing/app_hot_sale_section.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';

void main() {
  test('category page loads Hot sale listings of its own category', () async {
    final cubit = CategoryDetailCubit(
      repository: MockCategoryListingsRepository(latency: Duration.zero),
      categoryId: 'electronics',
    );
    await cubit.start();
    final hot = cubit.state.hotItems;
    expect(hot, isNotEmpty);
    expect(hot.every((item) => item.isFeatured), isTrue);
    expect(
      hot.every((item) => item.listing.categoryId == 'electronics'),
      isTrue,
    );
    await cubit.close();
  });

  testWidgets('Hot sale section shows the badge and hides when empty', (
    tester,
  ) async {
    final cubit = CategoryDetailCubit(
      repository: MockCategoryListingsRepository(latency: Duration.zero),
      categoryId: 'electronics',
    );
    await tester.runAsync(cubit.start);
    Widget app(Widget child) => MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );
    final opened = <String>[];
    await tester.pumpWidget(
      app(
        AppHotSaleSection(
          items: cubit.state.hotItems,
          onTap: (item) => opened.add(item.listing.id),
          onFavoriteTap: (_) {},
          // Font thử nghiệm rộng hơn font thật, thẻ 164 sẽ tràn chữ
          cardWidth: 240,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(find.bySemanticsLabel('Hot'), findsWidgets);
    await tester.tap(find.text(cubit.state.hotItems.first.listing.title));
    expect(opened, [cubit.state.hotItems.first.listing.id]);

    await tester.pumpWidget(
      app(
        AppHotSaleSection(
          items: const [],
          onTap: (_) {},
          onFavoriteTap: (_) {},
        ),
      ),
    );
    expect(find.byType(ListView), findsNothing);
    await cubit.close();
  });

  Widget localized(Widget home) => MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );

  testWidgets('category strip starts with Hot sale when it has a handler', (
    tester,
  ) async {
    var hotTaps = 0;
    final categories = [
      for (final json in ListingMockData.categories.take(2))
        CategoryModel.fromJson(json),
    ];
    await tester.pumpWidget(
      localized(
        Scaffold(
          body: HomeCategoryStrip(
            categories: categories,
            onTap: (_) {},
            onHotSaleTap: () => hotTaps++,
          ),
        ),
      ),
    );
    final labels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((s) => s.properties.label)
        .whereType<String>()
        .toList();
    expect(
      labels.indexOf('Hot sale'),
      lessThan(labels.indexOf(categories.first.name.resolve('vi'))),
    );
    await tester.tap(find.text('Hot sale'));
    expect(hotTaps, 1);
  });

  testWidgets('Hot sale page lists featured listings', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      localized(
        HotSaleView(repository: MockHotSaleRepository(latency: Duration.zero)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppListingCard), findsWidgets);
    expect(find.text('Chưa có tin Hot sale'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
