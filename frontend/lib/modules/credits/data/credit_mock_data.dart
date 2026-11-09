/// Dữ liệu mẫu ví xu, cùng cấu trúc JSON với API `/credits/*`.
/// Chỉ dùng trong test và khi bật USE_MOCK_DATA.
class CreditMockData {
  CreditMockData._();

  static const List<Map<String, dynamic>> packages = [
    {'id': 'p20', 'priceVnd': 20000, 'credits': 20, 'bonusCredits': 0},
    {'id': 'p50', 'priceVnd': 50000, 'credits': 50, 'bonusCredits': 2},
    {
      'id': 'p100',
      'priceVnd': 100000,
      'credits': 100,
      'bonusCredits': 10,
      'popular': true,
    },
    {'id': 'p200', 'priceVnd': 200000, 'credits': 200, 'bonusCredits': 30},
    {'id': 'p500', 'priceVnd': 500000, 'credits': 500, 'bonusCredits': 100},
  ];

  /// Sổ cái ban đầu: 95 xu nạp + 30 xu tặng, mới trước
  static List<Map<String, dynamic>> transactions(DateTime now) => [
    {
      'id': 't5',
      'type': 'SPEND',
      'bucket': 'BONUS',
      'amount': -5,
      'note': 'Đẩy tin · Honda Vision 2021',
      'createdAt': now.subtract(const Duration(days: 4)).toIso8601String(),
    },
    {
      'id': 't4',
      'type': 'TOPUP',
      'bucket': 'PAID',
      'amount': 100,
      'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
      'topupOrder': {
        'code': 'RS8F2K1X',
        'method': 'VNPAY',
        'amountVnd': 100000,
      },
    },
    {
      'id': 't3',
      'type': 'BONUS',
      'bucket': 'BONUS',
      'amount': 10,
      'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
      'expiresAt': now.add(const Duration(days: 83)).toIso8601String(),
      'topupOrder': {
        'code': 'RS8F2K1X',
        'method': 'VNPAY',
        'amountVnd': 100000,
      },
    },
    {
      'id': 't2',
      'type': 'REFUND',
      'bucket': 'BONUS',
      'amount': 25,
      'note': 'Tin bị từ chối: sai chuyên mục',
      'createdAt': now.subtract(const Duration(days: 9)).toIso8601String(),
    },
    {
      'id': 't1',
      'type': 'SPEND',
      'bucket': 'PAID',
      'amount': -5,
      'note': 'Đăng tin vượt hạn mức',
      'createdAt': now.subtract(const Duration(days: 12)).toIso8601String(),
    },
  ];
}
