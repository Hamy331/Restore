import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/feeds/models/feed_models.dart';
import 'package:restore/modules/feeds/repositories/feeds_repository.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/views/follow_list/follow_list_mobile_view.dart';
import 'package:restore/modules/my_shop/views/shop_followers/shop_followers_view.dart';
import 'package:restore/modules/trusted_shop/bloc/followed_shops/followed_shops_cubit.dart';
import 'package:restore/modules/trusted_shop/data/trusted_shop_mock_data.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/repositories/shop_following_repository.dart';
import 'package:restore/modules/trusted_shop/views/following_shops/following_shops_view.dart';
import 'package:restore/modules/following/views/following_hub/following_hub_view.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_follow_button.dart';

import 'support/fake_profile_repository.dart';

final _repo = MockShopFollowingRepository(latency: Duration.zero);

/// Bảng tin rỗng: trang Đang theo dõi không gọi API thật trong test
class _NoFeeds implements FeedsRepository {
  @override
  Future<FeedPage<FeedPost>> posts({
    bool following = false,
    String? authorId,
    String? cursor,
  }) async => const FeedPage([], null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/following-shops',
        builder: (_, _) => FollowingShopsView(repository: _repo),
      ),
      GoRoute(
        path: '/shops/:id',
        builder: (_, s) => Text('shop ${s.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp.router(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    TrustedShopMockData.followingShopIds
      ..clear()
      ..addAll({'shop_lumi', 'shop_kodo'});
  });

  test('FollowedShop đọc JSON của API, luôn là đang theo dõi', () {
    final shop = FollowedShop.fromJson({
      'id': 's1',
      'ownerId': 'u1',
      'name': 'Shop A',
      'followerCount': 3,
      'newListingCount': 2,
      'followedAt': '2026-11-10T00:00:00.000Z',
    });
    expect(shop.item.isFollowing, isTrue);
    expect(shop.newListingCount, 2);
    expect(shop.followedAt, DateTime.utc(2026, 11, 10));
    final off = shop.withFollowing(false);
    expect(off.item.isFollowing, isFalse);
    expect(off.item.shop.followerCount, 2);
  });

  test('ProfileData đọc followingShopCount', () {
    final profile = ProfileData.fromJson({
      'id': 'me',
      'followingCount': 2,
      'followingShopCount': 3,
    });
    expect(profile.followingShopCount, 3);
    expect(profile.copyWith(bio: 'x').followingShopCount, 3);
  });

  test('cubit bỏ theo dõi giữ dòng shop, đổi tổng số', () async {
    final cubit = FollowedShopsCubit(_repo);
    await cubit.load();
    expect(cubit.state.total, 2);
    final lumi = cubit.state.shops.firstWhere((s) => s.id == 'shop_lumi');
    await cubit.toggleFollow(lumi);
    expect(cubit.state.shops.length, 2);
    expect(cubit.state.total, 1);
    expect(TrustedShopMockData.followingShopIds, isNot(contains('shop_lumi')));
    await cubit.close();
  });

  testWidgets('trang Đang theo dõi của mình có tab Shop', (tester) async {
    await _pump(
      tester,
      FollowListMobileView(
        userId: 'me',
        repository: FakeProfileRepository(),
        shopRepository: _repo,
        showShops: true,
        openShops: true,
      ),
    );
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Lumi Lighting'), findsOneWidget);
    expect(find.text('Kodo Camera Official'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('followed-shops-feed')));
    await _settle(tester);
    expect(find.text('Shop bạn theo dõi'), findsOneWidget);
    expect(find.text('Tin mới nhất'), findsOneWidget);
  });

  testWidgets('hồ sơ người khác không có tab Shop', (tester) async {
    await _pump(
      tester,
      FollowListMobileView(userId: 'u2', repository: FakeProfileRepository()),
    );
    expect(find.text('Shop'), findsNothing);
  });

  testWidgets('chưa theo dõi shop nào thì mời khám phá', (tester) async {
    TrustedShopMockData.followingShopIds.clear();
    await _pump(tester, FollowingShopsView(repository: _repo));
    expect(find.text('Bạn chưa theo dõi shop nào'), findsOneWidget);
    expect(find.text('Khám phá Shop uy tín'), findsOneWidget);
  });

  testWidgets('trang người theo dõi shop', (tester) async {
    await _pump(tester, ShopFollowersView(repository: _repo));
    expect(find.text('Người theo dõi (4)'), findsOneWidget);
    expect(find.text('Nguyễn Thị Mai'), findsOneWidget);
  });

  testWidgets('trang Đang theo dõi: chưa theo dõi thì gợi ý, theo dõi xong '
      'xem tin và lọc theo shop', (tester) async {
    TrustedShopMockData.followingShopIds.clear();
    await _pump(
      tester,
      FollowingHubView(
        shopRepository: _repo,
        profileRepository: FakeProfileRepository(),
        feedsRepository: _NoFeeds(),
      ),
    );
    expect(find.text('Theo dõi shop để không bỏ lỡ tin mới'), findsOneWidget);
    expect(find.byKey(const ValueKey('following-hub-see-feed')), findsNothing);

    final kodo = find.byKey(const ValueKey('suggestion-shop_kodo'));
    await tester.tap(
      find.descendant(of: kodo, matching: find.byType(ShopFollowButton)),
    );
    await _settle(tester);
    expect(TrustedShopMockData.followingShopIds, contains('shop_kodo'));
    await tester.tap(find.text('Xem tin mới từ 1 shop'));
    await _settle(tester);

    expect(find.text('Mới từ shop bạn theo dõi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('following-filter-shop_kodo')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('following-open-shop')), findsOneWidget);
  });
}
