import 'package:flutter_test/flutter_test.dart';
import 'package:restore/main_admin_preview.dart';

void main() {
  testWidgets('admin preview starts without production credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const AdminPreviewApp());
    await tester.pumpAndSettle();
    expect(find.text('ReStore / Quản trị'), findsOneWidget);
    expect(
      find.text('Bản xem trước · Dữ liệu mẫu, thay đổi chỉ lưu trong phiên.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
