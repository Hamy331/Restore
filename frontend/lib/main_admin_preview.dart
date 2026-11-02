import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme.dart';
import 'modules/admin/presentation/admin_workspace.dart';

/// Dedicated UI preview. Does not initialize auth, Firebase, or production APIs.
void main() => runApp(const AdminPreviewApp());

class AdminPreviewApp extends StatelessWidget {
  const AdminPreviewApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ReStore Admin · Xem trước',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const AdminWorkspace(),
  );
}
