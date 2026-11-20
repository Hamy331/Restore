import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/credit_enums.dart';

/// Một lần được tặng xu còn trong ví (`GET /credits/bonus`), gần hết hạn trước
class CreditBonusBatch extends Equatable {
  final String id;

  /// [CreditTxnType.bonus] (tặng kèm khi nạp) hoặc [CreditTxnType.refund] (xu hoàn)
  final CreditTxnType type;

  /// Số xu của lần này còn trong ví
  final int amount;
  final DateTime grantedAt;

  /// null = không hết hạn
  final DateTime? expiresAt;

  const CreditBonusBatch({
    required this.id,
    required this.type,
    required this.amount,
    required this.grantedAt,
    this.expiresAt,
  });

  factory CreditBonusBatch.fromJson(Map<String, dynamic> json) =>
      CreditBonusBatch(
        id: '${json['id']}',
        type: CreditTxnType.fromApi(json['type'] as String?),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        grantedAt:
            DateTime.tryParse('${json['grantedAt']}')?.toLocal() ??
            DateTime.now(),
        expiresAt: DateTime.tryParse('${json['expiresAt']}')?.toLocal(),
      );

  /// Số ngày còn lại tới hạn (làm tròn lên), null khi không hết hạn
  int? daysLeft(DateTime now) {
    final expiresAt = this.expiresAt;
    if (expiresAt == null) return null;
    final hours = expiresAt.difference(now).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  @override
  List<Object?> get props => [id, type, amount, grantedAt, expiresAt];
}
