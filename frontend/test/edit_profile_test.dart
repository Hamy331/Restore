import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/modules/account/bloc/user_profile/user_profile_cubit.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/views/account/account_mobile_view.dart';
import 'package:restore/modules/account/bloc/account_listings/account_listings_cubit.dart';
import 'package:restore/modules/account/repositories/account_listings_repository.dart';
import 'package:restore/modules/account/widgets/profile_header.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/auth/bloc/auth/auth_state.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/account/repositories/profile_repository.dart';
import 'package:restore/modules/account/views/edit_profile/edit_profile_view.dart';
import 'package:restore/services/image_upload_service.dart';

import 'image_crop_test.dart' show testPng;

const _profile = ProfileData(
  id: 'shop-samsung',
  fullName: 'Samsung Store',
  username: 'samsung',
  followerCount: 0,
  followingCount: 0,
  ratingAverage: 0,
  avatarUrl: 'http://localhost:3000/api/v1/media/avatars/a.png',
  bio: 'Galaxy chính hãng',
);

class _FakeRepository implements ProfileRepository {
  Map<String, dynamic>? saved;
  String? error;
  ProfileData profile = _profile;
  Completer<ProfileData>? pendingRead;

  @override
  Future<ProfileData> getMe() async =>
      pendingRead == null ? profile : await pendingRead!.future;

  @override
  Future<ProfileData> getUser(String id) async => profile;

  @override
  Future<ProfileData> update(Map<String, dynamic> changes) async {
    if (error != null) throw ProfileUpdateException(error!);
    saved = changes;
    profile = profile.copyWith(
      fullName: changes['fullName'] as String?,
      username: changes['username'] as String?,
      bio: changes['bio'] as String?,
      avatarUrl: resolveMediaUrl(changes['avatarUrl'] as String?),
      clearAvatar:
          changes.containsKey('avatarUrl') && changes['avatarUrl'] == null,
    );
    return profile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUploader extends ImageUploadService {
  _FakeUploader() : super(dio: Dio());
  int? uploadedBytes;
  ImagePurpose? purpose;

  @override
  Future<String> uploadBytes(
    List<int> bytes, {
    ImagePurpose purpose = ImagePurpose.feed,
  }) async {
    uploadedBytes = bytes.length;
    this.purpose = purpose;
    return '/api/v1/media/avatars/shop-samsung_new.png';
  }
}

class _SessionRepository extends Fake implements AuthRepository {
  UserModel? saved;
  @override
  Future<void> cacheProfile(UserModel user) async {
    saved = user;
  }
}

Future<void> _pumpPage(
  WidgetTester tester,
  UserProfileCubit cubit,
  AvatarLoader loader,
) async {
  tester.view.physicalSize = const Size(420, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider(
              create: (_) =>
                  AccountListingsCubit(ApiAccountListingsRepository()),
            ),
            BlocProvider(
              create: (_) => AuthBloc(_SessionRepository())
                ..add(
                  LoggedIn(
                    UserModel(
                      id: _profile.id,
                      fullName: _profile.fullName,
                      email: 'seller@example.test',
                      username: _profile.username,
                      avatarUrl: _profile.avatarUrl,
                    ),
                  ),
                ),
            ),
          ],
          child: const Scaffold(body: AccountMobileView()),
        ),
      ),
      GoRoute(
        path: EditProfileView.path,
        builder: (_, _) => EditProfileView(cubit: cubit, avatarLoader: loader),
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
  await tester.tap(find.byType(ProfileAvatar));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test(
    'an older profile read cannot restore the previous avatar after saving',
    () async {
      final repo = _FakeRepository()..pendingRead = Completer<ProfileData>();
      final cubit = UserProfileCubit(repo, initial: _profile);
      final read = cubit.load();
      await cubit.update({'avatarUrl': null});
      repo.pendingRead!.complete(_profile);
      await read;
      expect(cubit.state.profile!.avatarUrl, isNull);
      expect((await repo.getUser(_profile.id)).avatarUrl, isNull);
      await cubit.close();
    },
  );
  testWidgets('re-crops the current avatar and saves it as a new upload', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final uploader = _FakeUploader();
    final cubit = UserProfileCubit(
      repository,
      uploader: uploader,
      initial: _profile,
    );
    final source = (await tester.runAsync(() => testPng(900, 600)))!;
    String? loaded;
    await _pumpPage(tester, cubit, (url) async {
      loaded = url;
      return source;
    });

    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('Samsung Store'), findsOneWidget);
    expect(find.text('Căn chỉnh'), findsOneWidget);

    // Căn chỉnh ảnh đang dùng: tải ảnh về rồi mở khung tròn
    await tester.tap(find.byKey(const ValueKey('edit-profile-adjust')));
    await _settle(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(loaded, _profile.avatarUrl);
    expect(find.text('Căn chỉnh ảnh đại diện'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('image-crop-area')),
      const Offset(-60, 0),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Dùng ảnh này'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await _settle(tester);
    expect(find.text('Căn chỉnh ảnh đại diện'), findsNothing);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('edit-profile-name')),
        matching: find.byType(TextField),
      ),
      'Samsung Official',
    );
    await tester.tap(find.text('Lưu'));
    await _settle(tester);

    expect(uploader.purpose, ImagePurpose.avatar);
    expect(uploader.uploadedBytes, greaterThan(0));
    expect(repository.saved, {
      'fullName': 'Samsung Official',
      'avatarUrl': '/api/v1/media/avatars/shop-samsung_new.png',
    });
    expect(cubit.state.profile!.avatarUrl, repository.profile.avatarUrl);
    // lưu xong thì quay về trang trước
    expect(find.byType(AccountMobileView), findsOneWidget);
    final auth = tester
        .element(find.byType(AccountMobileView))
        .read<AuthBloc>();
    expect(
      (auth.state as AuthAuthenticated).user.avatarUrl,
      repository.profile.avatarUrl,
    );
    expect(find.text('Đã lưu hồ sơ'), findsOneWidget);
    expect(tester.getSize(find.byType(SnackBar)).height, lessThan(100));
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('validates fields, shows a taken username and removes photo', (
    tester,
  ) async {
    final repository = _FakeRepository()..error = 'USERNAME_TAKEN';
    final cubit = UserProfileCubit(
      repository,
      uploader: _FakeUploader(),
      initial: _profile,
    );
    await _pumpPage(tester, cubit, (_) async => Uint8List(0));

    Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    );
    await tester.enterText(field('edit-profile-name'), '  ');
    await tester.enterText(field('edit-profile-username'), 'Bad Name');
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Nhập tên hiển thị.'), findsOneWidget);
    expect(repository.saved, isNull);

    await tester.enterText(field('edit-profile-name'), 'Samsung');
    await tester.enterText(field('edit-profile-username'), 'samsung.vn');
    await tester.tap(find.byKey(const ValueKey('edit-profile-remove')));
    await tester.pump();
    expect(find.text('Căn chỉnh'), findsNothing);
    await tester.tap(find.text('Lưu'));
    await _settle(tester);
    expect(find.text('Tên người dùng đã được sử dụng.'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Lưu'));
    await _settle(tester);
    expect(repository.saved?['avatarUrl'], isNull);
    expect(repository.saved!.containsKey('avatarUrl'), isTrue);
    expect(cubit.state.profile!.avatarUrl, isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
