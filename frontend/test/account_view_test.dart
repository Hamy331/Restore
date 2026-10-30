import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/account/views/account_view.dart';

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

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AccountView())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Hoàng Huy'), findsOneWidget);
    expect(find.text('Follower'), findsOneWidget);
    expect(find.text('ĐANG HIỂN THỊ (3)'), findsOneWidget);

    await tester.tap(find.byTooltip('Chỉnh sửa trang'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên hiển thị'),
      'Huy Nguyễn',
    );
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Huy Nguyễn'), findsOneWidget);

    await tester.tap(find.byTooltip('Menu và cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Xu ReStore'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    await tester.tapAt(const Offset(10, 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ẩn tin').first);
    await tester.pumpAndSettle();
    expect(find.text('ĐANG HIỂN THỊ (2)'), findsOneWidget);
    await tester.tap(find.text('ĐÃ ẨN (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Máy ảnh Fujifilm X-T20 kèm kit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
