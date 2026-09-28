import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/auth/views/welcome/welcome_view.dart';
import 'package:restore/shared/widgets/app_button.dart';

void main() {
  testWidgets('welcome foundation fits mobile and tablet widths', (
    tester,
  ) async {
    for (final size in <Size>[
      const Size(360, 812),
      const Size(375, 812),
      const Size(412, 915),
      const Size(768, 1024),
      const Size(1024, 1366),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const WelcomeView()),
      );
      await tester.pump();

      expect(find.text('ReStore'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'viewport: $size');
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('app button disables callback while loading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton(
            label: 'Lưu',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
