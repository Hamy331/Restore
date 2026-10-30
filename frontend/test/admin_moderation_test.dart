import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/admin/presentation/admin_dashboard.dart';
import 'package:restore/modules/admin/presentation/admin_moderation.dart';
import 'package:restore/modules/admin/presentation/admin_preview_data.dart';

void main() {
  testWidgets(
    'admin overview and moderation screens fit narrow and wide layouts',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [320.0, 1440.0]) {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        for (final screen in <Widget>[
          AdminDashboard(onNavigate: (_) {}),
          const AdminListingsView(),
          const AdminReportsView(),
          const AdminUsersView(),
        ]) {
          await tester.pumpWidget(
            BlocProvider(
              key: UniqueKey(),
              create: (_) => AdminPreviewCubit(),
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: Scaffold(body: SingleChildScrollView(child: screen)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} at $width',
          );
        }
      }
    },
  );
}
