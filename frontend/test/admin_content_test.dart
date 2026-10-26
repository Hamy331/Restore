import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/admin/presentation/admin_catalog.dart';
import 'package:restore/modules/admin/presentation/admin_posts.dart';
import 'package:restore/modules/admin/presentation/admin_preview_data.dart';

Future<void> openContent(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => AdminPreviewCubit(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SingleChildScrollView(child: screen)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('catalog prevents duplicate names and saves a new category', (
    tester,
  ) async {
    await openContent(tester, const AdminCatalogView());
    await tester.tap(find.text('Thêm danh mục'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên'),
      'Máy ảnh',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mô tả'),
      'Dụng cụ',
    );
    await tester.tap(find.text('Lưu bản mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Tên đã tồn tại.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên'),
      'Đồ thể thao',
    );
    await tester.tap(find.text('Lưu bản mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Đồ thể thao'), findsOneWidget);
    expect(find.text('Lưu bản mẫu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('article editor preserves unsaved text and saves a draft', (
    tester,
  ) async {
    await openContent(tester, const AdminPostsView());
    await tester.tap(find.text('Viết bài mới'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề bài viết'),
      'Bài viết thử nghiệm',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục viết'));
    await tester.pumpAndSettle();
    expect(find.text('Bài viết thử nghiệm'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nội dung'),
      'Kiểm tra sản phẩm trước khi giao dịch.',
    );
    await tester.ensureVisible(find.text('Lưu bài viết mẫu'));
    await tester.tap(find.text('Lưu bài viết mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Bài viết thử nghiệm'), findsOneWidget);
    expect(find.text('Lưu bài viết mẫu'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
