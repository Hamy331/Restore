import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/data/listing_repository.dart';
import 'package:restore/modules/listings/domain/entities/listing_preview.dart';
import 'package:restore/modules/listings/presentation/bloc/listing_form_cubit.dart';
import 'package:restore/modules/listings/presentation/views/create_listing_view.dart';
import 'package:restore/modules/stores/data/store_repository.dart';

class _FakeStoreRepository extends StoreRepository {
  _FakeStoreRepository() : super(dio: Dio());
  @override
  Future<List<StoreCategory>> categories() async => const [
    StoreCategory(id: 'furniture', name: 'Nội thất'),
  ];
}

class _FakeRepository extends ListingRepository {
  _FakeRepository() : super(dio: Dio());
  int calls = 0;
  bool fail = true;
  String? savedTitle;

  @override
  Future<ListingPreview> create({
    required String title,
    required String description,
    required String price,
    required String condition,
    required String categoryId,
    required bool isNegotiable,
  }) async {
    calls++;
    savedTitle = title;
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/listings'));
    }
    return const ListingPreview(
      id: 'created-1',
      title: 'Bàn gỗ sồi',
      price: '1.200.000 đ',
      location: '',
    );
  }
}

void main() {
  test('repository posts listing fields and reads the created ID', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/listings');
          expect(options.data, {
            'title': 'Bàn gỗ sồi',
            'description': 'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
            'price': '1200000',
            'condition': 'USED_GOOD',
            'categoryId': 'furniture',
            'isNegotiable': true,
          });
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'data': {
                  'id': 'created-1',
                  'title': 'Bàn gỗ sồi',
                  'description': 'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
                  'price': '1200000',
                  'condition': 'USED_GOOD',
                  'isNegotiable': true,
                  'images': <String>[],
                  'createdAt': '2026-10-05T00:00:00.000Z',
                  'owner': {'id': 'seller-1', 'fullName': 'Lan Nguyễn'},
                },
              },
            ),
          );
        },
      ),
    );
    final listing = await ListingRepository(dio: dio).create(
      title: 'Bàn gỗ sồi',
      description: 'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
      price: '1200000',
      condition: 'USED_GOOD',
      categoryId: 'furniture',
      isNegotiable: true,
    );
    expect(listing.id, 'created-1');
    expect(listing.isNegotiable, true);
  });

  test(
    'create listing validates, preserves form on API error, and can retry',
    () async {
      final repository = _FakeRepository();
      final form = ListingFormCubit(editing: false, repository: repository);
      addTearDown(form.close);

      form.nextStep();
      expect(form.state.step, 1);
      form.titleChanged('  Bàn gỗ sồi  ');
      form.categoryChanged('furniture');
      form.nextStep();
      expect(form.state.step, 2);
      await form.submit();
      expect(repository.calls, 0);

      form.priceChanged('1200000');
      form.descriptionChanged('Bàn gỗ sồi còn chắc chắn, dùng tốt.');
      await form.submit();
      expect(form.state.error, isNotEmpty);
      expect(form.state.description, isNotEmpty);
      expect(form.state.isSubmitting, false);

      repository.fail = false;
      await form.submit();
      expect(repository.calls, 2);
      expect(repository.savedTitle, 'Bàn gỗ sồi');
      expect(form.state.createdId, 'created-1');
    },
  );

  testWidgets('publish button opens the newly created listing', (tester) async {
    final repository = _FakeRepository()..fail = false;
    final router = GoRouter(
      initialLocation: '/create-listing',
      routes: [
        GoRoute(
          path: '/create-listing',
          builder: (_, _) => BlocProvider(
            create: (_) =>
                ListingFormCubit(editing: false, repository: repository),
            child: CreateListingView(storeRepository: _FakeStoreRepository()),
          ),
        ),
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Tin ${state.pathParameters['id']}')),
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
    await tester.tap(find.byKey(const ValueKey('listing-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nội thất').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Bàn gỗ sồi');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '1200000');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng tin'));
    await tester.pumpAndSettle();
    expect(find.text('Tin created-1'), findsOneWidget);
  });
}
