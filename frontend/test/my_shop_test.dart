import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/data/models/enums/shop_verification_type.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/my_shop/models/my_shop_overview.dart';
import 'package:restore/modules/my_shop/repositories/my_shop_repository.dart';
import 'package:restore/modules/my_shop/views/my_shop/my_shop_view.dart';

/// Ghi lại thay đổi gửi lên để kiểm tra
class _Repo extends MockMyShopRepository {
  _Repo(MyShopOverview initial)
    : super(initial: initial, latency: Duration.zero);

  final updates = <Map<String, dynamic>>[];
  int uploads = 0;

  @override
  Future<MyShopOverview> update(Map<String, dynamic> changes) {
    updates.add(changes);
    return super.update(changes);
  }

  @override
  Future<String> uploadImage(Uint8List bytes) async {
    uploads++;
    return '/api/v1/media/shops/me_$uploads.png';
  }
}

Future<void> _pump(WidgetTester tester, _Repo repository) async {
  tester.view.physicalSize = const Size(420, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => MyShopView(
          repository: repository,
          imageLoader: (_) async => Uint8List(0),
        ),
      ),
      GoRoute(
        path: '/plans',
        builder: (_, _) => const Scaffold(body: Text('plans page')),
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

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('personal plan sees the Store plan upsell', (tester) async {
    await _pump(tester, _Repo(const MyShopOverview()));
    expect(find.text('Trang shop dành cho gói Cửa hàng'), findsOneWidget);
    await tester.tap(find.text('Xem gói'));
    await _settle(tester);
    expect(find.text('plans page'), findsOneWidget);
  });

  testWidgets('store plan opens a shop then edits it', (tester) async {
    final repository = _Repo(
      const MyShopOverview(storePlan: true, canCreate: true),
    );
    await _pump(tester, repository);
    expect(find.text('Mở trang shop của bạn'), findsOneWidget);

    await tester.tap(find.text('Mở shop'));
    await tester.pump();
    expect(find.text('Tên shop từ 2 đến 60 ký tự.'), findsOneWidget);

    await tester.enterText(_field('my-shop-name'), 'Góc Gỗ');
    await tester.enterText(_field('my-shop-address'), 'Quận 3, TP.HCM');
    await tester.tap(find.text('Mở shop'));
    await _settle(tester);
    expect(find.text('Thông tin shop'), findsOneWidget);
    expect(find.text('Shop chưa xác minh'), findsOneWidget);
    // chưa đổi gì thì nút lưu tắt
    await tester.tap(find.text('Lưu thay đổi'));
    await _settle(tester);
    expect(repository.updates, isEmpty);

    await tester.enterText(_field('my-shop-tagline'), 'Đồ gỗ thủ công');
    await tester.enterText(_field('my-shop-address'), '');
    await tester.tap(find.byKey(const ValueKey('my-shop-color-1428A0')));
    await tester.pump();
    await tester.tap(find.text('Lưu thay đổi'));
    await _settle(tester);
    expect(repository.updates.single, {
      'tagline': 'Đồ gỗ thủ công',
      'address': null,
      'accentColor': '#1428A0',
    });
    expect(find.text('Đã lưu thông tin shop'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('verified shop: name locked, verified card, stats', (
    tester,
  ) async {
    final repository = _Repo(
      MyShopOverview(
        storePlan: false,
        nameLocked: true,
        stats: const MyShopStats(followerCount: 12, listingCount: 7),
        shop: ShopModel(
          id: 's1',
          name: 'Kodo Camera',
          verificationType: ShopVerificationType.certified,
          verifiedAt: DateTime(2026, 10),
          certificateCode: 'RS-2026-00128',
          logoUrl: 'assets/images/shops/canon.png',
        ),
      ),
    );
    await _pump(tester, repository);
    expect(find.text('Shop đã xác minh'), findsOneWidget);
    expect(find.textContaining('RS-2026-00128'), findsOneWidget);
    expect(find.text('Gói Cửa hàng đã hết hạn'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    final name = tester.widget<TextField>(_field('my-shop-name'));
    expect(name.enabled, isFalse);
    expect(find.byKey(const ValueKey('my-shop-view-public')), findsOneWidget);

    // xoá logo qua bảng chọn rồi lưu
    await tester.tap(find.byKey(const ValueKey('my-shop-logo')));
    await _settle(tester);
    await tester.tap(find.text('Xóa ảnh'));
    await _settle(tester);
    await tester.tap(find.text('Lưu thay đổi'));
    await _settle(tester);
    expect(repository.updates.single, {'logoUrl': null});
    await tester.pump(const Duration(seconds: 5));
  });
}
