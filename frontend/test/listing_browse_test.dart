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
  Future<ListingPreview> get(String id) async {
    if (id != item.id) throw StateError('wrong listing ID: $id');
    return item;
  }
}

void main() {
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
          builder: (_, _) => Scaffold(body: HomeView(repository: repository)),
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

  testWidgets('search sends the entered title to the listings API', (
    tester,
  ) async {
    final repository = _FakeListings();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SearchView(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bàn gỗ');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repository.queries.last, 'bàn gỗ');
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
