import 'package:equatable/equatable.dart';

/// Một ngày mở cửa của shop: [day] theo `DateTime.weekday` (1 = thứ Hai,
/// 7 = Chủ nhật), [open] < [close] dạng "HH:MM"
class ShopOpeningDay extends Equatable {
  const ShopOpeningDay({
    required this.day,
    required this.open,
    required this.close,
  });

  final int day;
  final String open, close;

  static List<ShopOpeningDay> listFromJson(Object? json) => [
    for (final item in json is List ? json : const [])
      if (item is Map && item['day'] is num)
        ShopOpeningDay(
          day: (item['day'] as num).toInt(),
          open: '${item['open']}',
          close: '${item['close']}',
        ),
  ];

  Map<String, dynamic> toJson() => {'day': day, 'open': open, 'close': close};

  @override
  List<Object?> get props => [day, open, close];
}

/// Shop đang mở hay đã đóng lúc [now]: đang mở thì [closesAt]; đã đóng thì
/// lần mở kế tiếp [opensAt] vào [opensDay] (null = hôm nay)
typedef ShopOpenState = ({
  bool open,
  String? closesAt,
  String? opensAt,
  int? opensDay,
});

int _minutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// null khi shop chưa đặt giờ mở cửa
ShopOpenState? shopOpenStateAt(List<ShopOpeningDay> hours, DateTime now) {
  if (hours.isEmpty) return null;
  final byDay = {for (final item in hours) item.day: item};
  final minute = now.hour * 60 + now.minute;
  final today = byDay[now.weekday];
  if (today != null) {
    if (minute >= _minutes(today.open) && minute < _minutes(today.close)) {
      return (open: true, closesAt: today.close, opensAt: null, opensDay: null);
    }
    if (minute < _minutes(today.open)) {
      return (open: false, closesAt: null, opensAt: today.open, opensDay: null);
    }
  }
  for (var offset = 1; offset <= 7; offset++) {
    final day = (now.weekday - 1 + offset) % 7 + 1;
    final next = byDay[day];
    if (next != null) {
      return (open: false, closesAt: null, opensAt: next.open, opensDay: day);
    }
  }
  return null;
}
