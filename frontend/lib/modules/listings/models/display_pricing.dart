import 'package:equatable/equatable.dart';

/// Mốc mua ngày hiển thị rẻ hơn (30 / 60 / 90 ngày)
class DisplayDayPack extends Equatable {
  final int days;
  final int discountPercent;

  const DisplayDayPack({required this.days, required this.discountPercent});

  factory DisplayDayPack.fromJson(Map<String, dynamic> json) => DisplayDayPack(
    days: (json['days'] as num).toInt(),
    discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [days, discountPercent];
}

/// Một mốc gợi ý thay cho số ngày lẻ
class SuggestedDayPack extends Equatable {
  final int days;
  final int credits;

  const SuggestedDayPack({required this.days, required this.credits});

  @override
  List<Object?> get props => [days, credits];
}

/// Cách tính giá ngày hiển thị của gói tài khoản, nhận trong
/// `GET /listings/posting-quota` (trường `display`). Cùng công thức với
/// backend (display-pricing.ts) để báo giá ngay khi chọn ngày; backend vẫn
/// tính lại khi đăng / gia hạn.
///
/// Giá một ngày = giá 30 ngày của chuyên mục / 30. Mua đúng một mốc thì giảm
/// theo mốc, rồi giảm theo gói; làm tròn lên, ít nhất 1 xu.
class DisplayPricing extends Equatable {
  final List<DisplayDayPack> packs;

  /// Ngày miễn phí theo % của chuyên mục (Cá nhân 100, Bán chuyên 150, Cửa hàng 200)
  final int freeDaysPercent;

  /// Giảm giá (%) khi mua thêm ngày
  final int extendDiscountPercent;

  /// Gói được bật tự gia hạn 30 ngày
  final bool autoExtend;

  /// Hẹn ngày bắt đầu xa nhất (tính từ hôm nay)
  final int maxStartDelayDays;

  /// Số ngày mỗi lần tự gia hạn
  static const int autoExtendDays = 30;

  const DisplayPricing({
    this.packs = defaultPacks,
    this.freeDaysPercent = 100,
    this.extendDiscountPercent = 0,
    this.autoExtend = false,
    this.maxStartDelayDays = 14,
  });

  static const List<DisplayDayPack> defaultPacks = [
    DisplayDayPack(days: 30, discountPercent: 10),
    DisplayDayPack(days: 60, discountPercent: 20),
    DisplayDayPack(days: 90, discountPercent: 30),
  ];

  factory DisplayPricing.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DisplayPricing();
    final packs = [
      for (final item in json['packs'] as List? ?? const [])
        DisplayDayPack.fromJson(Map<String, dynamic>.from(item as Map)),
    ]..sort((a, b) => a.days.compareTo(b.days));
    return DisplayPricing(
      packs: packs,
      freeDaysPercent: (json['freeDaysPercent'] as num?)?.toInt() ?? 100,
      extendDiscountPercent:
          (json['extendDiscountPercent'] as num?)?.toInt() ?? 0,
      autoExtend: json['autoExtend'] == true,
      maxStartDelayDays: (json['maxStartDelayDays'] as num?)?.toInt() ?? 14,
    );
  }

  static int _percent(int value) => value.clamp(0, 100);

  DisplayDayPack? packFor(int days) {
    for (final pack in packs) {
      if (pack.days == days) return pack;
    }
    return null;
  }

  /// Giá xu cho [days] ngày thêm với giá 30 ngày [dayPackCredits] của chuyên mục
  int extraDaysCredits(int days, int dayPackCredits, {bool usePack = true}) {
    if (days <= 0) return 0;
    final pack = usePack ? packFor(days)?.discountPercent ?? 0 : 0;
    // Số nguyên để làm tròn giống backend: ngày x giá30 x (100 - mốc) x (100 - gói) / 300.000
    final numerator =
        days *
        dayPackCredits *
        (100 - _percent(pack)) *
        (100 - _percent(extendDiscountPercent));
    final credits = (numerator + 299999) ~/ 300000;
    return credits < 1 ? 1 : credits;
  }

  /// Số xu tiết kiệm khi [days] đúng một mốc (0 nếu không phải mốc)
  int packSaving(int days, int dayPackCredits) {
    if (packFor(days) == null) return 0;
    return extraDaysCredits(days, dayPackCredits, usePack: false) -
        extraDaysCredits(days, dayPackCredits);
  }

  /// Mốc nhỏ nhất dài hơn [days], không quá [maxDays], mà giá không cao hơn
  SuggestedDayPack? suggestedPack(int days, int maxDays, int dayPackCredits) {
    if (days <= 0 || packFor(days) != null) return null;
    final price = extraDaysCredits(days, dayPackCredits);
    for (final pack in packs) {
      if (pack.days <= days || pack.days > maxDays) continue;
      final credits = extraDaysCredits(pack.days, dayPackCredits);
      if (credits <= price) {
        return SuggestedDayPack(days: pack.days, credits: credits);
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    packs,
    freeDaysPercent,
    extendDiscountPercent,
    autoExtend,
    maxStartDelayDays,
  ];
}
