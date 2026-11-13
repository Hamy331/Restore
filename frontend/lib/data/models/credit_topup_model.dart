import 'package:equatable/equatable.dart';

import 'enums/credit_enums.dart';

/// Thông tin chuyển khoản VietQR của một đơn nạp
class VietQrInfo extends Equatable {
  final String accountNo;
  final String accountName;

  /// Nội dung chuyển khoản (= mã đơn), phải giữ nguyên để xu vào tự động
  final String content;
  final String imageUrl;

  const VietQrInfo({
    required this.accountNo,
    required this.accountName,
    required this.content,
    required this.imageUrl,
  });

  factory VietQrInfo.fromJson(Map<String, dynamic> json) => VietQrInfo(
    accountNo: '${json['accountNo'] ?? ''}',
    accountName: '${json['accountName'] ?? ''}',
    content: '${json['content'] ?? ''}',
    imageUrl: '${json['imageUrl'] ?? ''}',
  );

  @override
  List<Object?> get props => [accountNo, accountName, content, imageUrl];
}

/// Đơn nạp xu (bảng CreditTopupOrder) kèm cách trả do backend trả về
class CreditTopupModel extends Equatable {
  final String id;

  /// Mã ngắn, VD RS8F2K1X
  final String code;
  final TopupStatus status;
  final CreditPayMethod method;
  final int amountVnd;
  final int credits;
  final int bonusCredits;
  final DateTime expiresAt;
  final DateTime? paidAt;

  /// Đang ở chế độ thử: được giả lập kết quả trả tiền
  final bool sandbox;

  /// Trang thanh toán của cổng (ZaloPay), null khi máy chủ chưa cấu hình cổng
  final String? payUrl;
  final VietQrInfo? vietQr;

  const CreditTopupModel({
    required this.id,
    required this.code,
    required this.status,
    required this.method,
    required this.amountVnd,
    required this.credits,
    required this.bonusCredits,
    required this.expiresAt,
    this.paidAt,
    this.sandbox = false,
    this.payUrl,
    this.vietQr,
  });

  int get totalCredits => credits + bonusCredits;

  factory CreditTopupModel.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    final pay = payment is Map ? Map<String, dynamic>.from(payment) : const {};
    final vietQr = pay['vietQr'];
    return CreditTopupModel(
      id: '${json['id']}',
      code: '${json['code'] ?? ''}',
      status: TopupStatus.fromApi(json['status'] as String?),
      method: CreditPayMethod.fromApi(json['method'] as String?),
      amountVnd: (json['amountVnd'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      bonusCredits: (json['bonusCredits'] as num?)?.toInt() ?? 0,
      expiresAt:
          DateTime.tryParse('${json['expiresAt']}')?.toLocal() ??
          DateTime.now(),
      paidAt: DateTime.tryParse('${json['paidAt']}')?.toLocal(),
      sandbox: pay['sandbox'] == true,
      payUrl: pay['payUrl'] as String?,
      vietQr: vietQr is Map
          ? VietQrInfo.fromJson(Map<String, dynamic>.from(vietQr))
          : null,
    );
  }

  CreditTopupModel copyWith({TopupStatus? status, DateTime? paidAt}) =>
      CreditTopupModel(
        id: id,
        code: code,
        status: status ?? this.status,
        method: method,
        amountVnd: amountVnd,
        credits: credits,
        bonusCredits: bonusCredits,
        expiresAt: expiresAt,
        paidAt: paidAt ?? this.paidAt,
        sandbox: sandbox,
        payUrl: payUrl,
        vietQr: vietQr,
      );

  @override
  List<Object?> get props => [id, code, status, method, amountVnd, paidAt];
}
