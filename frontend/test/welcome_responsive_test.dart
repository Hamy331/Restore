import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/auth/views/welcome/welcome_view.dart';

void main() {
  testWidgets('welcome content and actions fit without scrolling', (
    tester,
  ) async {
    for (final size in <Size>[
      const Size(360, 640),
      const Size(360, 812),
      const Size(375, 812),
      const Size(412, 915),
      const Size(600, 960),
      const Size(768, 1024),
      const Size(1024, 1366),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const WelcomeView()),
      );
      await tester.pump();

      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull, reason: 'viewport: $size');

      for (final visibleElement in <Finder>[
        find.text('ReStore'),
        find.byType(Image),
        find.text('Một tài khoản để vừa mua vừa bán.'),
        find.text('Đăng nhập'),
        find.text('Đăng ký'),
        find.text('Tiếp tục xem tin không cần tài khoản ›'),
      ]) {
        final rect = tester.getRect(visibleElement);
        expect(rect.left, greaterThanOrEqualTo(0), reason: 'viewport: $size');
        expect(rect.top, greaterThanOrEqualTo(0), reason: 'viewport: $size');
        expect(
          rect.right,
          lessThanOrEqualTo(size.width),
          reason: 'viewport: $size',
        );
        expect(
          rect.bottom,
          lessThanOrEqualTo(size.height),
          reason: 'viewport: $size',
        );
      }
      expect(tester.takeException(), isNull, reason: 'viewport: $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
