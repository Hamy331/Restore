/// Trạng thái tài khoản (AccountStatus) 
enum AccountStatus {
  unverified('UNVERIFIED'),
  active('ACTIVE'),
  suspended('SUSPENDED'),
  banned('BANNED');

  const AccountStatus(this.apiValue);

  final String apiValue;

  static AccountStatus fromApi(String? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => AccountStatus.unverified,
  );
}
