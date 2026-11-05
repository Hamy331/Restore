import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';

void main() {
  test('app uses real data and API authentication', () {
    expect(AppEnvironment.useMockData, isFalse);
    expect(AuthRepository(), isA<ApiAuthRepository>());
  });

  test('plan simulation is disabled by default', () {
    expect(DevPlanOverride.enabled, isFalse);
  });
}
