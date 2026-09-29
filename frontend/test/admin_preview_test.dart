import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/admin/presentation/admin_preview_data.dart';
import 'package:restore/modules/admin/presentation/admin_workspace.dart';

void main() {
  test('moderation validates reasons and refuses stale decisions', () async {
    final cubit = AdminPreviewCubit();
    expect(cubit.moderate('TD-0248', pendingListing, 'Từ chối', ' '), isFalse);
    expect(
      cubit.moderate('TD-0248', pendingListing, activeListing, ''),
      isTrue,
    );
    expect(
      cubit.moderate('TD-0248', pendingListing, 'Từ chối', 'Ảnh sai'),
      isFalse,
    );
    expect(cubit.state.listings.first.status, activeListing);
    expect(cubit.state.logs.length, 1);
    await cubit.close();
  });

  test('report resolution updates target and report atomically', () async {
    final cubit = AdminPreviewCubit();
    expect(cubit.resolve('BC-1035', 'Đã cấm', 'Sai đối tượng'), isFalse);
    expect(cubit.resolve('BC-1035', 'Gỡ tin', ''), isFalse);
    expect(cubit.resolve('BC-1035', 'Gỡ tin', 'Nội dung sai'), isTrue);
    expect(
      cubit.state.listings.singleWhere((x) => x.id == 'TD-0245').status,
      'Đã gỡ',
    );
    expect(cubit.state.reports.first.status, 'Đã giải quyết');
    expect(cubit.resolve('BC-1035', 'Giữ tin', 'Lần hai'), isFalse);
    expect(
      cubit.state.logs.map((x) => x.target),
      containsAll(['BC-1035', 'TD-0245']),
    );
    expect(cubit.resolve('BC-1034', 'Đình chỉ', 'Vi phạm', days: 7), isTrue);
    expect(cubit.state.users.last.status, 'Đình chỉ');
    expect(cubit.state.logs.first.reason, contains('7 ngày'));
    cubit.reset();
    expect(cubit.state.logs, isEmpty);
    expect(cubit.state.users.last.status, 'Hoạt động');
    await cubit.close();
  });

  testWidgets('all admin sections fit mobile, tablet and desktop', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [
      const Size(320, 900),
      const Size(768, 1024),
      const Size(1024, 900),
      const Size(1440, 1000),
    ]) {
      await setAdminTestSize(tester, size);
      for (var section = 0; section < adminDestinations.length; section++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AdminWorkspace(
              key: ValueKey('$size-$section'),
              initialSection: section,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${adminDestinations[section].$1} at $size',
        );
      }
    }
  });

  testWidgets('rejecting a listing requires a reason and updates the table', (
    tester,
  ) async {
    await setAdminTestSize(tester, const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminWorkspace(initialSection: 1),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem chi tiết').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ra quyết định'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Từ chối').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận trên bản mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập lý do.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lý do / Kết luận'),
      'Cần ảnh thực tế của sản phẩm',
    );
    await tester.tap(find.text('Xác nhận trên bản mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Ra quyết định'), findsNothing);
    expect(find.textContaining('Cần ảnh thực tế của sản phẩm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog duplicate validation and package price validation', (
    tester,
  ) async {
    await setAdminTestSize(tester, const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminWorkspace(initialSection: 4),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm danh mục'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên'),
      'Máy ảnh',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mô tả'),
      'Trùng danh mục',
    );
    await tester.tap(find.text('Lưu bản mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Tên đã tồn tại.'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-nav-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gói Boost'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm gói Boost'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên gói'),
      'Gói thử',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Giá (VND)'),
      '-1',
    );
    await tester.tap(find.text('Lưu gói mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập số nguyên lớn hơn 0.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> setAdminTestSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(size);
}
