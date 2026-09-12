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

  @override
  String get successTitle => 'Thành công';

  @override
  String get errorTitle => 'Đã xảy ra lỗi';

  @override
  String get warningTitle => 'Cảnh báo';

  @override
  String get infoTitle => 'Thông tin';

  @override
  String get deviceNotSupported => 'Thiết bị không được hỗ trợ';

  @override
  String get deviceNotSupportedDesc =>
      'Ứng dụng ReStore hiện tại chỉ được thiết kế và tối ưu cho trải nghiệm trên màn hình điện thoại di động cầm tay.';

  @override
  String get loginSuccessMsg => 'Đăng nhập vào hệ thống thành công.';

  @override
  String get loginErrorMsg => 'Sai tài khoản hoặc mật khẩu.';
}
