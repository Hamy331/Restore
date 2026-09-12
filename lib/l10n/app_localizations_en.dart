// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ReStore';

  @override
  String get loginTitle => 'Login to your Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get orSignInWith => 'Or sign in with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get successTitle => 'Success';

  @override
  String get errorTitle => 'Error occurred';

  @override
  String get warningTitle => 'Warning';

  @override
  String get infoTitle => 'Information';

  @override
  String get deviceNotSupported => 'Device not supported';

  @override
  String get deviceNotSupportedDesc =>
      'The ReStore application is currently designed and optimized exclusively for mobile handheld experiences.';

  @override
  String get loginSuccessMsg => 'Successfully logged into the system.';

  @override
  String get loginErrorMsg => 'Invalid email or password.';
}
