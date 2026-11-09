/// Cách trả tiền khi nạp xu (CreditPayMethod)
enum CreditPayMethod {
  vnpay('VNPAY'),
  vietQr('VIETQR');

  const CreditPayMethod(this.apiValue);

  final String apiValue;

  static CreditPayMethod fromApi(String? value) => values.firstWhere(
    (method) => method.apiValue == value,
    orElse: () => CreditPayMethod.vnpay,
  );
}

/// Trạng thái đơn nạp xu (TopupStatus)
enum TopupStatus {
  pending('PENDING'),
  paid('PAID'),
  failed('FAILED'),
  expired('EXPIRED'),
  refunded('REFUNDED');

  const TopupStatus(this.apiValue);

  final String apiValue;

  static TopupStatus fromApi(String? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => TopupStatus.pending,
  );
}

/// Loại bút toán trong sổ cái xu (CreditTxnType)
enum CreditTxnType {
  topup('TOPUP'),
  bonus('BONUS'),
  spend('SPEND'),
  refund('REFUND'),
  expire('EXPIRE'),
  adjust('ADJUST');

  const CreditTxnType(this.apiValue);

  final String apiValue;

  static CreditTxnType fromApi(String? value) => values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => CreditTxnType.adjust,
  );
}
