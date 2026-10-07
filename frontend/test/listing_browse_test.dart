import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/home/views/home_view.dart';
import 'package:restore/modules/listings/data/listing_repository.dart';
import 'package:restore/modules/listings/domain/entities/listing_preview.dart';
import 'package:restore/modules/listings/presentation/views/product_detail_view.dart';
import 'package:restore/modules/listings/presentation/views/search_view.dart';
import 'package:restore/modules/stores/data/store_repository.dart';

class _FakeCategories extends StoreRepository {
  _FakeCategories() : super(dio: Dio());
  @override
  Future<List<StoreCategory>> categories() async => const [
    StoreCategory(id: 'furniture', name: 'Nội thất'),
  ];
}

class _FakeListings extends ListingRepository {
  _FakeListings() : super(dio: Dio());
  final queries = <String>[];

  static const item = ListingPreview(
    id: 'real-id-1',
    title: 'Bàn gỗ sồi từ API',
    price: '1.200.000 đ',
    location: 'Đăng 05/10/2026',
    description: 'Bàn còn chắc chắn.',
    sellerName: 'Lan Nguyễn',
    sellerId: 'seller-1',
    imageCount: 0,
  );

  @override
  Future<ListingPage> list({int page = 1, String query = ''}) async {
    queries.add(query);
    return const ListingPage([item], 1, 1);
  }

  @override
  Future<ListingPage> search({
    int page = 1,
    String query = '',
    String categoryId = '',
    String condition = '',
    String minPrice = '',
    String maxPrice = '',
  }) async {
    queries.add('$query|$categoryId|$condition|$minPrice|$maxPrice');
    return const ListingPage([item], 1, 1);
  }

  @override
  Future<ListingPreview> get(String id) async {
    if (id != item.id) throw StateError('wrong listing ID: $id');
    return item;
  }
}

void main() {
  test('search sends category, condition and price range to API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(
            options.queryParameters,
            containsPair('categoryId', 'furniture'),
          );
          expect(
            options.queryParameters,
            containsPair('condition', 'USED_GOOD'),
          );
          expect(options.queryParameters, containsPair('minPrice', '100000'));
          expect(options.queryParameters, containsPair('maxPrice', '500000'));
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': <Map<String, dynamic>>[],
                'pagination': {'totalItems': 0, 'totalPages': 0},
              },
            ),
          );
        },
      ),
    );
    final result = await ListingRepository(dio: dio).search(
      categoryId: 'furniture',
      condition: 'USED_GOOD',
      minPrice: '100000',
      maxPrice: '500000',
    );
    expect(result.items, isEmpty);
  });
  test('repository reads the paginated API payload and detail by ID', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    final payload = {
      'id': 'real-id-1',
      'title': 'Bàn gỗ sồi từ API',
      'description': 'Bàn còn chắc chắn.',
      'price': '1200000',
      'condition': 'USED_GOOD',
      'images': <String>[],
      'createdAt': '2026-10-05T00:00:00.000Z',
      'owner': {'id': 'seller-1', 'fullName': 'Lan Nguyễn'},
    };
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, startsWith('/listings'));
          final body = options.path == '/listings'
              ? {
                  'data': [payload],
                  'pagination': {'totalItems': 1, 'totalPages': 1},
                }
              : {'data': payload};
          handler.resolve(Response(requestOptions: options, data: body));
        },
      ),
    );
    final repository = ListingRepository(dio: dio);
    final page = await repository.list();
    final detail = await repository.get(page.items.single.id);
    expect(page.totalItems, 1);
    expect(detail.title, 'Bàn gỗ sồi từ API');
    expect(detail.price, '1.200.000 đ');
    expect(detail.condition, 'Đã sử dụng, còn tốt');
  });

  testWidgets('home card opens the matching listing detail', (tester) async {
    final repository = _FakeListings();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => Scaffold(
            body: HomeView(
              repository: repository,
              storeRepository: _FakeCategories(),
            ),
          ),
        ),
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) => ProductDetailView(
            listingId: state.pathParameters['id']!,
            repository: repository,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bàn gỗ sồi từ API'), findsOneWidget);

    await tester.ensureVisible(find.text('Bàn gỗ sồi từ API'));
    await tester.tap(find.text('Bàn gỗ sồi từ API'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailView), findsOneWidget);
    expect(find.text('Bàn còn chắc chắn.'), findsOneWidget);
    expect(find.text('Lan Nguyễn'), findsOneWidget);
  });

  testWidgets('home category opens search with its real category ID', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => Scaffold(
            body: HomeView(
              repository: _FakeListings(),
              storeRepository: _FakeCategories(),
            ),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (_, state) => Scaffold(
            body: Text('Danh mục: ${state.uri.queryParameters['categoryId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nội thất'));
    await tester.pumpAndSettle();
    expect(find.text('Danh mục: furniture'), findsOneWidget);
  });

  testWidgets('search sends the entered title to the listings API', (
    tester,
  ) async {
    final repository = _FakeListings();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchView(
            repository: repository,
            storeRepository: _FakeCategories(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'bàn gỗ');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repository.queries.last, 'bàn gỗ||||');
  });

  testWidgets('search filters by selected category and price', (tester) async {
    final repository = _FakeListings();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchView(
            repository: repository,
            storeRepository: _FakeCategories(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nội thất').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('search-min-price')),
      '100000',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repository.queries.last, '|furniture||100000|');
  });

  testWidgets('missing listing shows an error instead of another item', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ProductDetailView(
          listingId: 'missing-id',
          repository: _FakeListings(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không mở được tin đăng'), findsOneWidget);
    expect(find.text('Bàn gỗ sồi từ API'), findsNothing);
  });
}
