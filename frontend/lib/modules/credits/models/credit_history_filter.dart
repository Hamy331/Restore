/// Bộ lọc trang lịch sử xu, khớp query `type` của `GET /credits/transactions`
enum CreditHistoryFilter {
  all(null),
  topup('topup'),
  spend('spend'),
  refund('refund');

  const CreditHistoryFilter(this.apiValue);

  final String? apiValue;
}
