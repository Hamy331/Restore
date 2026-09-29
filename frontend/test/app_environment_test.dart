import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/config/app_environment.dart';

void main() {
  test('uses the Android emulator API URL by default', () {
    expect(AppEnvironment.apiBaseUrl, 'http://10.0.2.2:3000/api/v1');
  });
}
