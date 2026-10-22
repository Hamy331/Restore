import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/services/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'token writes do not overlap and unreadable credentials are cleared',
    () async {
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final values = <String, String>{'jwt_token': 'legacy'};
      var active = 0, maximum = 0, corrupt = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            final key = args['key'] as String;
            if (call.method == 'write') {
              active++;
              if (active > maximum) maximum = active;
              await Future<void>.delayed(Duration.zero);
              values[key] = args['value'] as String;
              active--;
            } else if (call.method == 'read') {
              if (corrupt) throw PlatformException(code: 'decrypt_failed');
              return values[key];
            } else if (call.method == 'delete') {
              values.remove(key);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final storage = TokenStorage();
      await storage.writeTokens(accessToken: 'access', refreshToken: 'refresh');
      expect(maximum, 1);
      expect(await storage.readAccessToken(), 'access');
      expect(await storage.readRefreshToken(), 'refresh');
      expect(values.containsKey('jwt_token'), false);
      corrupt = true;
      expect(await storage.readAccessToken(), isNull);
      expect(values, isEmpty);
    },
  );
}
