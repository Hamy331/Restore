import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/bloc/account_listings/account_listings_cubit.dart';
import 'package:restore/modules/account/models/account_listing.dart';
import 'package:restore/modules/account/bloc/follow_list/follow_list_cubit.dart';
import 'package:restore/modules/account/bloc/public_profile/public_profile_cubit.dart';
import 'package:restore/modules/account/bloc/user_profile/user_profile_cubit.dart';
import 'package:restore/modules/account/bloc/user_profile/user_profile_state.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'support/fake_account_listings_repository.dart';
import 'support/fake_profile_repository.dart';
import 'package:restore/modules/account/views/account/account_view.dart';

Widget host(Widget child) => BlocProvider(
  create: (_) => AuthBloc(MockAuthRepository(latency: Duration.zero)),
  child: MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('account profile opens menu and moves a listing to hidden', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(host(account()));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Hoàng Huy'), findsOneWidget);
    expect(find.text('Người theo dõi'), findsOneWidget);
    expect(find.text('4.9 (12 đánh giá)'), findsOneWidget);
    expect(find.text('ĐANG HIỂN THỊ (3)'), findsOneWidget);
    expect(find.textContaining('Điện tử · Đăng 2 ngày trước'), findsOneWidget);

    await tester.tap(find.byTooltip('Chỉnh sửa trang'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên hiển thị'),
      'Huy Nguyễn',
    );
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Huy Nguyễn'), findsOneWidget);

    await tester.tap(find.text('Tạo cửa hàng'));
    await tester.pump();
    expect(find.text('Tính năng này đang được phát triển'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(AccountView)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hoạt động'), findsOneWidget);
    expect(find.text('Chỉnh sửa'), findsWidgets);

    await tester.tap(find.byTooltip('Menu và cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Xu ReStore'), findsOneWidget);
    expect(find.text('Đánh giá từ tôi'), findsOneWidget);
    expect(find.text('Cửa hàng / chuyên trang'), findsOneWidget);
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất khỏi ReStore?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ẩn tin').first);
    await tester.pumpAndSettle();
    expect(find.text('ĐANG HIỂN THỊ (2)'), findsOneWidget);
    await tester.tap(find.text('ĐÃ ẨN (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Máy ảnh Fujifilm X-T20 kèm kit'), findsOneWidget);
    await tester.tap(find.text('CHỜ DUYỆT (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có tin chờ duyệt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit dialog validates and reports a taken username', (
    tester,
  ) async {
    await tester.pumpWidget(host(account()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chỉnh sửa trang'));
    await tester.pumpAndSettle();
    final username = find.widgetWithText(TextFormField, 'Tên người dùng');
    await tester.enterText(username, 'Bad Name');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(
      find.text('3–30 ký tự: chữ thường, số, dấu chấm hoặc gạch dưới.'),
      findsOneWidget,
    );
    await tester.enterText(username, 'taken');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Tên người dùng đã được sử dụng.'), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
  });

  test('listings load per tab and move between tabs', () async {
    final cubit = AccountListingsCubit(FakeAccountListingsRepository());
    await cubit.load();
    expect(cubit.state.count(AccountListingStatus.visible), 3);
    expect(cubit.state.count(AccountListingStatus.hidden), 0);
    await cubit.setStatus('101', AccountListingStatus.hidden);
    expect(cubit.state.count(AccountListingStatus.visible), 2);
    expect(cubit.state.count(AccountListingStatus.hidden), 1);
    cubit.select(AccountListingStatus.hidden);
    expect(cubit.state.displayed.single.id, '101');
    await cubit.close();
  });

  test('public profile follows and updates the follower count', () async {
    final cubit = PublicProfileCubit(FakeProfileRepository(), 'other');
    await cubit.load();
    expect(cubit.state.profile!.isFollowing, isFalse);
    await cubit.toggleFollow();
    expect(cubit.state.profile!.isFollowing, isTrue);
    expect(cubit.state.profile!.followerCount, 1);
    await cubit.toggleFollow();
    expect(cubit.state.profile!.followerCount, 0);
    await cubit.close();
  });

  test('follow list toggles a user in place', () async {
    final repository = _FollowRepository();
    final cubit = FollowListCubit(repository, 'me', FollowListKind.followers);
    await cubit.load();
    expect(cubit.state.users.single.isFollowing, isFalse);
    await cubit.toggleFollow(cubit.state.users.single);
    expect(cubit.state.users.single.isFollowing, isTrue);
    expect(repository.followed, ['u1']);
    await cubit.close();
  });

  test('saving maps backend username errors', () async {
    final cubit = UserProfileCubit(FakeProfileRepository());
    await cubit.load();
    expect(
      await cubit.update({'username': 'taken'}),
      ProfileSaveResult.usernameTaken,
    );
    expect(await cubit.update({'username': 'fine'}), ProfileSaveResult.saved);
    expect(cubit.state.profile!.username, 'fine');
    await cubit.close();
  });
}

class _FollowRepository extends FakeProfileRepository {
  final followed = <String>[];
  @override
  Future<void> follow(String id) async => followed.add(id);
  @override
  Future<({List<FollowUser> items, bool hasMore})> follows(
    String id,
    FollowListKind kind, {
    int page = 1,
  }) async => (
    items: const [FollowUser(id: 'u1', fullName: 'Lan', username: 'lan')],
    hasMore: false,
  );
}

/// Trang tài khoản dùng dữ liệu trong bộ nhớ thay cho API.
Widget account() => AccountView(
  profileRepository: FakeProfileRepository(),
  listingsRepository: FakeAccountListingsRepository(),
);
