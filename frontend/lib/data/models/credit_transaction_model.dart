import 'package:equatable/equatable.dart';

import 'enums/credit_enums.dart';

/// Một bút toán trong sổ cái xu (bảng CreditTransaction).
/// [amount] dương là cộng, âm là trừ.
class CreditTransactionModel extends Equatable {
  final String id;
  final CreditTxnType type;
  final int amount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? note;

  /// Đơn nạp liên quan (khi type là nạp / tặng)
  final String? topupCode;
  final CreditPayMethod? topupMethod;
  final int? topupAmountVnd;

  const CreditTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.expiresAt,
    this.note,
    this.topupCode,
    this.topupMethod,
    this.topupAmountVnd,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    final order = json['topupOrder'];
    final topup = order is Map ? Map<String, dynamic>.from(order) : null;
    return CreditTransactionModel(
      id: '${json['id']}',
      type: CreditTxnType.fromApi(json['type'] as String?),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse('${json['createdAt']}')?.toLocal() ??
          DateTime.now(),
      expiresAt: DateTime.tryParse('${json['expiresAt']}')?.toLocal(),
      note: json['note'] as String?,
      topupCode: topup?['code'] as String?,
      topupMethod: topup == null
          ? null
          : CreditPayMethod.fromApi(topup['method'] as String?),
      topupAmountVnd: (topup?['amountVnd'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [id, type, amount, createdAt];
}
