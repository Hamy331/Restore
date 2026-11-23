import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/shop_opening_hours.dart';

void main() {
  // T2-T6 8:00-21:00, T7 9:00-17:00, CN nghỉ
  final hours = [
    for (var day = 1; day <= 5; day++)
      ShopOpeningDay(day: day, open: '08:00', close: '21:00'),
    const ShopOpeningDay(day: 6, open: '09:00', close: '17:00'),
  ];
  // 23/11/2026 là thứ Hai, 28/11 thứ Bảy, 29/11 Chủ nhật
  DateTime at(int date, int hour, [int minute = 0]) =>
      DateTime(2026, 11, date, hour, minute);

  test('đang mở thì báo giờ đóng, trước giờ mở thì báo mở hôm nay', () {
    expect(shopOpenStateAt(hours, at(23, 10)), (
      open: true,
      closesAt: '21:00',
      opensAt: null,
      opensDay: null,
    ));
    final early = shopOpenStateAt(hours, at(23, 7, 59))!;
    expect([early.open, early.opensAt, early.opensDay], [false, '08:00', null]);
  });

  test('đúng giờ đóng là đã đóng, mở lại ngày kế tiếp có lịch', () {
    final closed = shopOpenStateAt(hours, at(23, 21))!;
    expect([closed.open, closed.opensAt, closed.opensDay], [false, '08:00', 2]);
    // thứ Bảy sau 17h và Chủ nhật: bỏ qua ngày nghỉ, mở lại thứ Hai
    expect(shopOpenStateAt(hours, at(28, 18))?.opensDay, 1);
    expect(shopOpenStateAt(hours, at(29, 12))?.opensDay, 1);
  });

  test('chưa đặt giờ thì null; đọc JSON bỏ qua dòng sai', () {
    expect(shopOpenStateAt(const [], at(23, 10)), isNull);
    expect(
      ShopOpeningDay.listFromJson([
        {'day': 2, 'open': '07:30', 'close': '11:00'},
        'x',
        {'open': '08:00'},
      ]),
      [const ShopOpeningDay(day: 2, open: '07:30', close: '11:00')],
    );
    expect(ShopOpeningDay.listFromJson(null), isEmpty);
  });
}
