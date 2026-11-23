import 'dart:io';
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
import 'package:restore/services/media_picker_service.dart';

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

  final verifications = <Map<String, Object>>[];

  @override
  Future<MyShopOverview> requestVerification({
    required String businessName,
    required String taxCode,
    required List<String> documentUrls,
  }) {
    verifications.add({
      'businessName': businessName,
      'taxCode': taxCode,
      'documentUrls': documentUrls,
    });
    return super.requestVerification(
      businessName: businessName,
      taxCode: taxCode,
      documentUrls: documentUrls,
    );
  }
}

/// Chọn ảnh = trả về file tạm có sẵn
class _Picker extends MediaPickerService {
  _Picker(this.path);

  final String path;

  @override
  Future<List<String>> pickImages({
    required MediaSource source,
    required int limit,
  }) async => [path];
}

Future<void> _pump(
  WidgetTester tester,
  _Repo repository, {
  MediaPickerService? picker,
}) async {
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
          picker: picker,
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
  _approvedShopTests();

  testWidgets('personal plan sees the Store plan upsell', (tester) async {
    await _pump(tester, _Repo(const MyShopOverview()));
    expect(find.text('Trang shop dành cho gói Cửa hàng Pro'), findsOneWidget);
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
    // shop mới mở vào hàng chờ duyệt, chưa có nút xem trang công khai
    expect(find.text('Shop đang chờ duyệt'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-shop-view-public')), findsNothing);
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
    expect(find.text('Gói Cửa hàng Pro đã hết hạn'), findsOneWidget);
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

  testWidgets('rejected shop shows the reason and resubmits on save', (
    tester,
  ) async {
    final repository = _Repo(
      const MyShopOverview(
        storePlan: true,
        reviewStatus: 'REJECTED',
        rejectNote: 'Ảnh bìa có logo thương hiệu khác',
        shop: ShopModel(id: 's1', name: 'Góc Gỗ'),
      ),
    );
    await _pump(tester, repository);
    expect(find.text('Shop chưa được duyệt'), findsOneWidget);
    expect(
      find.textContaining('Ảnh bìa có logo thương hiệu khác'),
      findsOneWidget,
    );

    await tester.enterText(_field('my-shop-tagline'), 'Đồ gỗ thủ công');
    await tester.pump();
    await tester.tap(find.text('Lưu thay đổi'));
    await _settle(tester);
    expect(repository.updates.single, {'tagline': 'Đồ gỗ thủ công'});
    // kéo về đầu trang để thấy thẻ trạng thái
    await tester.drag(
      find.byKey(const ValueKey('my-shop-list')),
      const Offset(0, 2000),
    );
    await _settle(tester);
    expect(find.text('Shop đang chờ duyệt'), findsOneWidget);
    expect(find.text('Shop chưa được duyệt'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}

/// Shop đã duyệt, chưa xác minh: giờ mở cửa và hồ sơ xác minh
void _approvedShopTests() {
  const approved = MyShopOverview(
    storePlan: true,
    reviewStatus: 'APPROVED',
    nameLocked: true,
    shop: ShopModel(id: 's1', name: 'Góc Gỗ'),
  );

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
  }

  testWidgets('opening hours: pick days, save sends one range per day', (
    tester,
  ) async {
    final repository = _Repo(approved);
    await _pump(tester, repository);
    await tapKey(tester, 'my-shop-day-1');
    await tapKey(tester, 'my-shop-day-7');
    expect(find.textContaining('08:00'), findsOneWidget);
    await tester.tap(find.text('Lưu thay đổi'));
    await _settle(tester);
    expect(repository.updates.single, {
      'openingHours': [
        {'day': 1, 'open': '08:00', 'close': '21:00'},
        {'day': 7, 'open': '08:00', 'close': '21:00'},
      ],
    });
    // form dựng lại theo giờ đã lưu; bỏ hết ngày là xoá giờ mở cửa
    await tapKey(tester, 'my-shop-day-1');
    await tapKey(tester, 'my-shop-day-7');
    await tester.tap(find.text('Lưu thay đổi'));
    await _settle(tester);
    expect(repository.updates.last, {'openingHours': null});
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('verification: validate, attach licence, send, then pending', (
    tester,
  ) async {
    final file = File(
      '${Directory.systemTemp.createTempSync('restore-verify').path}/gpkd.png',
    )..writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);
    final repository = _Repo(approved);
    await _pump(tester, repository, picker: _Picker(file.path));
    expect(find.text('Xác minh cửa hàng'), findsOneWidget);

    await tapKey(tester, 'my-shop-verify-submit');
    expect(find.text('Thêm ít nhất 1 ảnh giấy phép.'), findsOneWidget);
    expect(repository.verifications, isEmpty);

    await tester.enterText(
      _field('my-shop-verify-name'),
      'Hộ kinh doanh Góc Gỗ',
    );
    await tester.enterText(_field('my-shop-verify-tax'), '031234567');
    await tester.pump();
    expect(
      find.text('Mã số thuế gồm 10 số, chi nhánh thêm -001.'),
      findsOneWidget,
    );
    await tester.enterText(_field('my-shop-verify-tax'), '0312345678');
    // đọc file ảnh thật phải chạy ngoài fake async
    final add = find.byKey(const ValueKey('my-shop-verify-add'));
    await tester.ensureVisible(add);
    await tester.runAsync(() async {
      await tester.tap(add);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    await tapKey(tester, 'my-shop-verify-submit');
    await _settle(tester);
    expect(repository.verifications.single, {
      'businessName': 'Hộ kinh doanh Góc Gỗ',
      'taxCode': '0312345678',
      'documentUrls': ['/api/v1/media/verifications/me_mock-1.jpg'],
    });
    expect(find.byKey(const ValueKey('my-shop-verify')), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('my-shop-list')),
      const Offset(0, 3000),
    );
    await _settle(tester);
    expect(find.text('Đang xét hồ sơ xác minh'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('rejected verification shows the reason and the form again', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo(
        const MyShopOverview(
          storePlan: true,
          reviewStatus: 'APPROVED',
          verificationStatus: 'REJECTED',
          verificationNote: 'Ảnh giấy phép bị mờ',
          shop: ShopModel(id: 's1', name: 'Góc Gỗ'),
        ),
      ),
    );
    expect(find.text('Hồ sơ xác minh chưa được duyệt'), findsOneWidget);
    expect(find.textContaining('Ảnh giấy phép bị mờ'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-shop-verify')), findsOneWidget);
  });
}
