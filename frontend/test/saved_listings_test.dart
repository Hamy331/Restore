import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/modules/saved_listings/bloc/saved_listings_cubit.dart';
import 'package:restore/modules/saved_listings/data/recently_viewed_store.dart';
import 'package:restore/modules/saved_listings/repositories/saved_listings_repository.dart';
import 'package:restore/modules/saved_listings/views/saved_listings_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final ids = [
    for (final json in HomeMockData.listings(DateTime.now())) '${json['id']}',
  ];
  setUp(() {
    MockFavoriteStore.ids.clear();
    SharedPreferences.setMockInitialValues({});
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

  test('unsaving keeps the card so it can be saved again', () async {
    MockFavoriteStore.set(ids[0], true);
    MockFavoriteStore.set(ids[1], true);
    final cubit = SavedListingsCubit(
      repository: MockSavedListingsRepository(latency: Duration.zero),
    );
    await cubit.start();
    expect(cubit.state.items.map((item) => item.listing.id), ids.take(2));
    expect(cubit.state.items.every((item) => item.isFavorite), isTrue);

    await cubit.toggleFavorite(cubit.state.items.first);
    expect(cubit.state.items, hasLength(2));
    expect(cubit.state.items.first.isFavorite, isFalse);
    expect(MockFavoriteStore.contains(ids[0]), isFalse);

    await cubit.refresh();
    expect(cubit.state.items.map((item) => item.listing.id), [ids[1]]);
    await cubit.close();
  });

  testWidgets('saved page shows saved listings, or the empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    Widget page() => localized(
      SavedListingsView(
        key: UniqueKey(),
        repository: MockSavedListingsRepository(latency: Duration.zero),
      ),
    );

    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('Chưa có tin đã lưu'), findsOneWidget);

    MockFavoriteStore.set(ids[0], true);
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('Tin đã lưu'), findsOneWidget);
    expect(find.byType(AppListingCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'recently viewed keeps newest first, no duplicates, at most 30',
    () async {
      for (var i = 0; i < 35; i++) {
        await RecentlyViewedStore.add('id$i');
      }
      await RecentlyViewedStore.add('id10');
      final ids = await RecentlyViewedStore.ids();
      expect(ids, hasLength(RecentlyViewedStore.maxItems));
      expect(ids.take(3), ['id10', 'id34', 'id33']);
      expect(ids.where((id) => id == 'id10'), hasLength(1));
    },
  );

  testWidgets('recently viewed page lists opened listings in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    Widget page() => localized(
      SavedListingsView(
        key: UniqueKey(),
        recent: true,
        repository: MockRecentlyViewedRepository(latency: Duration.zero),
      ),
    );

    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('Xem gần đây'), findsOneWidget);
    expect(find.text('Chưa xem tin nào'), findsOneWidget);

    await tester.runAsync(() async {
      await RecentlyViewedStore.add(ids[0]);
      await RecentlyViewedStore.add(ids[1]);
    });
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    final cards = tester.widgetList<AppListingCard>(
      find.byType(AppListingCard),
    );
    expect(cards.map((card) => card.item.listing.id), [ids[1], ids[0]]);
    expect(tester.takeException(), isNull);
  });
}
