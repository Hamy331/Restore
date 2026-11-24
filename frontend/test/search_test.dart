import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_follow_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/search/bloc/search_accounts_cubit.dart';
import 'package:restore/modules/search/bloc/search_cubit.dart';
import 'package:restore/modules/search/bloc/search_results_cubit.dart';
import 'package:restore/modules/search/bloc/search_results_state.dart';
import 'package:restore/modules/search/views/search_results/search_results_mobile_view.dart';
import 'package:restore/modules/search/bloc/search_state.dart';
import 'package:restore/modules/search/views/search/widgets/search_suggestion_list.dart';
import 'package:restore/modules/search/repositories/search_repository.dart';
import 'package:restore/shared/models/listing_filter.dart';

/// ApiClient trả [data] cho mọi request và ghi lại request cuối
(ApiClient, List<RequestOptions>) _fakeClient(Map<String, dynamic> data) {
  final client = ApiClient();
  final requests = <RequestOptions>[];
  client.dio.interceptors.insert(
    0,
    InterceptorsWrapper(
      onRequest: (request, handler) {
        requests.add(request);
        handler.resolve(
          Response(requestOptions: request, data: data, statusCode: 200),
        );
      },
    ),
  );
  return (client, requests);
}

void main() {
  test(
    'search sends filters in the shape GET /listings/search expects',
    () async {
      final (client, requests) = _fakeClient({
        'data': <Object>[],
        'meta': {'page': 2, 'limit': 10, 'hasMore': false},
      });
      final result = await ApiSearchRepository(apiClient: client).search(
        'ghế gỗ',
        const ListingFilter(
          sort: ListingSort.priceLow,
          dealTypes: {ListingDealType.buy, ListingDealType.exchange},
          conditions: {ListingCondition.newItem, ListingCondition.usedGood},
          minPrice: 100000,
        ),
        page: 2,
      );
      final request = requests.single;
      expect(request.path, '/listings/search');
      expect(request.queryParameters, {
        'q': 'ghế gỗ',
        'deal': 'buy,exchange',
        'sort': 'price_asc',
        'minPrice': 100000,
        'condition': 'NEW,USED_GOOD',
        'page': 2,
        'limit': SearchRepository.pageSize,
      });
      expect(result.hasMore, isFalse);
    },
  );

  test('history and suggestions parse the search API', () async {
    final (client, requests) = _fakeClient({
      'data': [
        {
          'id': 'h1',
          'keyword': 'Ghế gỗ',
          'searchedAt': '2026-11-16T10:00:00.000Z',
        },
      ],
    });
    final history = await ApiSearchRepository(apiClient: client).getHistory();
    expect(requests.single.path, '/search/history');
    expect(history.single.keyword, 'Ghế gỗ');
    expect(history.single.searchedAt, DateTime.utc(2026, 11, 16, 10));

    final (suggestClient, suggestRequests) = _fakeClient({
      'data': ['ghế gỗ', 'Ghế gỗ sồi Bắc Âu'],
    });
    final suggestions = await ApiSearchRepository(
      apiClient: suggestClient,
    ).getSuggestions('ghe');
    expect(suggestRequests.single.path, '/search/suggestions');
    expect(suggestRequests.single.queryParameters['q'], 'ghe');
    expect(suggestions, ['ghế gỗ', 'Ghế gỗ sồi Bắc Âu']);
  });

  test('guests see quick picks but no search history', () async {
    final repository = MockSearchRepository(latency: Duration.zero);
    final guest = SearchCubit(searchRepository: repository, showHistory: false);
    await guest.start();
    expect(guest.state.trending, isNotEmpty);
    expect(guest.state.history, isEmpty);
    await guest.close();

    final member = SearchCubit(searchRepository: repository);
    await member.start();
    expect(member.state.history, isNotEmpty);
    await member.close();
  });

  test(
    'mock account search matches names without accents and @username',
    () async {
      final repository = MockSearchRepository(latency: Duration.zero);
      final shops = await repository.searchShops('kodo');
      expect(shops.items.map((item) => item.shop.id), ['shop_kodo']);
      expect((await repository.searchShops('@kodo.cam')).items, hasLength(1));

      final binh = await repository.searchUsers('binh');
      expect(binh.items.map((user) => user.id), ['user_binh']);
      expect(
        (await repository.searchUsers('lan.decor')).items.first.id,
        'user_lan',
      );
      // Gõ "@" chỉ xét username, không xét tên hiển thị
      expect((await repository.searchUsers('@tran')).items, isEmpty);
      expect((await repository.searchUsers('@lan')).items.first.id, 'user_lan');
      expect((await repository.searchUsers('  ')).items, isEmpty);
    },
  );

  test('account search parses GET /search/shops and /search/users', () async {
    final (client, requests) = _fakeClient({
      'data': [
        {
          'id': 'u1',
          'fullName': 'Nguyễn Văn Bình',
          'username': 'binh',
          'followerCount': 3,
          'listingCount': 2,
          'isFollowing': true,
          'shopId': 's1',
        },
      ],
      'meta': {'hasMore': false},
      'pagination': {'totalItems': 1},
    });
    final users = await ApiSearchRepository(
      apiClient: client,
    ).searchUsers('binh', limit: 2);
    expect(requests.last.path, '/search/users');
    expect(requests.last.queryParameters, {'q': 'binh', 'page': 1, 'limit': 2});
    final user = users.items.single;
    expect(
      [user.fullName, user.isFollowing, user.hasShop],
      ['Nguyễn Văn Bình', true, true],
    );
    expect(users.hasMore, isFalse);
  });

  test('typing loads a few matching shops and users', () async {
    final cubit = SearchCubit(
      searchRepository: MockSearchRepository(latency: Duration.zero),
      query: 'kodo',
    );
    await cubit.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(cubit.state.shops.map((item) => item.shop.id), ['shop_kodo']);
    // Chủ shop chỉ hiện một lần, ở dạng shop
    expect(cubit.state.users, isEmpty);
    cubit.queryChanged('');
    expect(cubit.state.shops, isEmpty);
    expect(cubit.state.users, isEmpty);
    await cubit.close();
  });

  testWidgets('suggestion list shows shops and users above keywords', (
    tester,
  ) async {
    final repository = MockSearchRepository(latency: Duration.zero);
    late final SearchState state;
    await tester.runAsync(() async {
      state = SearchState(
        query: 'kodo',
        shops: (await repository.searchShops('kodo')).items,
        users: (await repository.searchUsers('lan')).items,
        accountsQuery: 'kodo',
      );
    });
    String? openedShop;
    String? openedUser;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SearchSuggestionList(
            state: state,
            onSubmit: (_) {},
            onFill: (_) {},
            onRemoveHistory: (_) {},
            onOpenShop: (item) => openedShop = item.shop.id,
            onOpenUser: (user) => openedUser = user.id,
            onOpenCategory: (_) {},
          ),
        ),
      ),
    );
    expect(find.textContaining('tin đang bán'), findsNWidgets(2));
    // Dòng shop có @username chủ shop
    expect(find.textContaining('@kodo.camera ·'), findsOneWidget);
    await tester.tap(find.textContaining('@kodo.camera'));
    await tester.tap(find.textContaining('@lan.decor'));
    expect([openedShop, openedUser], ['shop_kodo', 'user_lan']);
  });

  test('results page loads matching shops and users with paging', () async {
    final cubit = SearchAccountsCubit(
      searchRepository: MockSearchRepository(latency: Duration.zero),
      query: 'o',
    );
    await cubit.start();
    expect(cubit.state.shops.status, SearchResultsStatus.ready);
    expect(cubit.state.shops.items, isNotEmpty);
    expect(
      cubit.state.users.items.map((user) => user.id),
      isNot(contains('user_kodo')),
      reason: 'chủ shop hiện ở tab Cửa hàng',
    );
    final shop = cubit.state.shops.items.first;
    cubit.syncShopFollowing(shop.shop.id, !shop.isFollowing);
    expect(cubit.state.shops.items.first.isFollowing, !shop.isFollowing);
    await cubit.close();
  });

  test('follow buttons toggle shops and users right away', () async {
    final repository = MockSearchRepository(latency: Duration.zero);
    final cubit = SearchAccountsCubit(searchRepository: repository, query: 'n');
    await cubit.start();
    final shop = cubit.state.shops.items.first;
    final user = cubit.state.users.items.firstWhere((u) => !u.isFollowing);
    await cubit.toggleShopFollowing(shop);
    await cubit.toggleUserFollowing(user);
    expect(cubit.state.shops.items.first.isFollowing, !shop.isFollowing);
    expect(
      cubit.state.users.items.firstWhere((u) => u.id == user.id).isFollowing,
      isTrue,
    );
    // Mock giữ trạng thái khi tải lại
    await cubit.reloadUsers();
    expect(
      cubit.state.users.items.firstWhere((u) => u.id == user.id).isFollowing,
      isTrue,
    );
    await cubit.toggleUserFollowing(
      cubit.state.users.items.firstWhere((u) => u.id == user.id),
    );
    await cubit.toggleShopFollowing(cubit.state.shops.items.first);
    await cubit.close();
  });

  testWidgets('results show listing filters and matching shops without tabs', (
    tester,
  ) async {
    final repository = MockSearchRepository(latency: Duration.zero);
    final results = SearchResultsCubit(
      searchRepository: repository,
      query: 'kodo',
    );
    final accounts = SearchAccountsCubit(
      searchRepository: repository,
      query: 'kodo',
    );
    await tester.runAsync(
      () => Future.wait([results.start(), accounts.start()]),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    AuthBloc(MockAuthRepository(latency: Duration.zero)),
              ),
              BlocProvider.value(value: results),
              BlocProvider.value(value: accounts),
            ],
            child: const SearchResultsMobileView(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
    expect(find.text('Cửa hàng phù hợp'), findsOneWidget);
    expect(find.text('Lọc'), findsOneWidget);

    expect(find.text('Tin đăng'), findsNothing);
    expect(find.text('Cửa hàng'), findsNothing);
    expect(find.text('Người dùng'), findsNothing);
    await tester.tap(find.text('Xem tất cả'));
    await tester.pumpAndSettle();
    expect(find.textContaining('@kodo.camera ·'), findsOneWidget);
    expect(find.byType(ShopFollowButton), findsWidgets);
    // Chờ danh mục mẫu (trễ giả lập) tải xong trước khi đóng trang
    await tester.pump(const Duration(seconds: 1));
    await results.close();
    await accounts.close();
  });
}
