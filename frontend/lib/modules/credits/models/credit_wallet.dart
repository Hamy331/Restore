import 'package:equatable/equatable.dart';

/// Số dư ví xu (`GET /credits/wallet`)
class CreditWallet extends Equatable {
  /// Xu dùng được = xu nạp + xu tặng
  final int available;
  final int paid;
  final int bonus;

  /// Xu đang giữ cho tin chờ duyệt
  final int held;

  /// Hạn gần nhất của xu tặng, null khi không còn xu tặng
  final DateTime? nextBonusExpiry;

  const CreditWallet({
    this.available = 0,
    this.paid = 0,
    this.bonus = 0,
    this.held = 0,
    this.nextBonusExpiry,
  });

  factory CreditWallet.fromJson(Map<String, dynamic> json) => CreditWallet(
    available: (json['available'] as num?)?.toInt() ?? 0,
    paid: (json['paid'] as num?)?.toInt() ?? 0,
    bonus: (json['bonus'] as num?)?.toInt() ?? 0,
    held: (json['held'] as num?)?.toInt() ?? 0,
    nextBonusExpiry: DateTime.tryParse('${json['nextBonusExpiry']}')?.toLocal(),
  );

  @override
  List<Object?> get props => [available, paid, bonus, held, nextBonusExpiry];
}
