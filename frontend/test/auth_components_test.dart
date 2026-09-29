import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/auth/widgets/auth_primitives.dart';
import 'package:restore/modules/auth/widgets/otp_input.dart';

void main() {
  testWidgets('OTP input accepts and advances through six digits', (
    tester,
  ) async {
    var value = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 335,
            child: OtpInput(onChanged: (otp) => value = otp),
          ),
        ),
      ),
    );

    for (var index = 0; index < 6; index++) {
      await tester.enterText(find.byType(TextField).at(index), '${index + 1}');
    }
    expect(value, '123456');
  });

  testWidgets('auth feedback exposes the error message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AuthFeedback(message: 'Email chưa đúng định dạng.'),
        ),
      ),
    );

    expect(find.text('Email chưa đúng định dạng.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
