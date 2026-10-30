import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/chat/models/chat_models.dart';

void main() {
  test(
    'chat presence shows online and elapsed hours from server timestamp',
    () {
      final now = DateTime.now();
      final online = ChatPerson(
        id: 'a',
        fullName: 'Minh Anh',
        lastActiveAt: now.subtract(const Duration(seconds: 30)),
      );
      final offline = ChatPerson(
        id: 'b',
        fullName: 'Huy',
        lastActiveAt: now.subtract(const Duration(hours: 4, minutes: 5)),
      );
      expect(activityLabel(online), 'Đang hoạt động');
      expect(activityLabel(offline), 'Hoạt động 4 giờ trước');
    },
  );
}
