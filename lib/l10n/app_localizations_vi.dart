// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'ReStore';

  @override
  String get loginTitle => 'Đăng nhập vào tài khoản';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get orSignInWith => 'Hoặc đăng nhập bằng';

  @override
  String get dontHaveAccount => 'Bạn chưa có tài khoản?';

  @override
  String get signUp => 'Đăng ký';
}
