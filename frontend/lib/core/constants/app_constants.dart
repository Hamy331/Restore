import '../config/app_environment.dart';

class ApiConstants {
  static final String baseUrl = AppEnvironment.apiBaseUrl;

  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}
