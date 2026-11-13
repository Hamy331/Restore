import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/credit_package_model.dart';
import 'package:restore/data/models/credit_topup_model.dart';
import 'package:restore/data/models/credit_transaction_model.dart';
import 'package:restore/data/models/enums/credit_enums.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/credit_mock_data.dart';
import '../models/credit_history_filter.dart';
import '../models/credit_wallet.dart';

/// Lỗi nghiệp vụ từ API xu, [code] là mã lỗi backend
/// (VD `TOPUP_TOO_MANY_PENDING`), null khi lỗi mạng hoặc không rõ.
class CreditException implements Exception {
  final String? code;

  const CreditException([this.code]);

  bool get isTooManyPending => code == 'TOPUP_TOO_MANY_PENDING';

  @override
  String toString() => 'CreditException($code)';
}

/// Ví Xu ReStore (tên trong code: credit). Hợp đồng API: `/credits/*`.
abstract class CreditRepository {
  static const int pageSize = 20;

  Future<CreditWallet> getWallet();

  Future<List<CreditPackageModel>> getPackages();

  /// Lịch sử xu, mới trước, [page] bắt đầu từ 1
  Future<PagedResult<CreditTransactionModel>> getTransactions({
    int page = 1,
    int limit = pageSize,
    CreditHistoryFilter filter = CreditHistoryFilter.all,
  });

  /// Tạo đơn nạp chờ trả (hết hạn sau 15 phút)
  Future<CreditTopupModel> createTopup(
    String packageId,
    CreditPayMethod method,
  );

  Future<CreditTopupModel> getTopup(String id);

  Future<void> cancelTopup(String id);

  /// Cổng thử: giả lập cổng trả về [success]. Chỉ có ở chế độ sandbox.
  Future<CreditTopupModel> simulate(String id, {required bool success});
}

/// Dữ liệu mẫu giữ trong bộ nhớ (còn nguyên khi mở lại trang)
class MockCreditRepository implements CreditRepository {
  MockCreditRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  static List<Map<String, dynamic>>? _transactions;
  static final Map<String, Map<String, dynamic>> _orders = {};
  static int _nextId = 1;

  /// Xoá dữ liệu đã đổi (dùng trong test)
  static void reset() {
    _transactions = null;
    _orders.clear();
    _nextId = 1;
  }

  List<Map<String, dynamic>> get _ledger =>
      _transactions ??= CreditMockData.transactions(DateTime.now());

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<CreditWallet> getWallet() async {
    await _wait();
    var paid = 0;
    var bonus = 0;
    DateTime? expiry;
    for (final row in _ledger) {
      final amount = row['amount'] as int;
      if (row['bucket'] == 'BONUS') {
        bonus += amount;
        final expires = DateTime.tryParse('${row['expiresAt']}');
        if (amount > 0 &&
            expires != null &&
            (expiry == null || expires.isBefore(expiry))) {
          expiry = expires;
        }
      } else {
        paid += amount;
      }
    }
    return CreditWallet(
      available: paid + bonus,
      paid: paid,
      bonus: bonus,
      nextBonusExpiry: bonus > 0 ? expiry : null,
    );
  }

  @override
  Future<List<CreditPackageModel>> getPackages() async {
    await _wait();
    return [
      for (final json in CreditMockData.packages)
        CreditPackageModel.fromJson(json),
    ];
  }

  static const _filterTypes = {
    CreditHistoryFilter.topup: {'TOPUP', 'BONUS'},
    CreditHistoryFilter.spend: {'SPEND', 'EXPIRE'},
    CreditHistoryFilter.refund: {'REFUND'},
  };

  @override
  Future<PagedResult<CreditTransactionModel>> getTransactions({
    int page = 1,
    int limit = CreditRepository.pageSize,
    CreditHistoryFilter filter = CreditHistoryFilter.all,
  }) async {
    await _wait();
    final types = _filterTypes[filter];
    final rows = [
      for (final row in _ledger)
        if (types == null || types.contains(row['type'])) row,
    ];
    final start = (page - 1) * limit;
    final slice = rows.skip(start).take(limit);
    return PagedResult(
      items: [for (final row in slice) CreditTransactionModel.fromJson(row)],
      page: page,
      hasMore: start + limit < rows.length,
      totalItems: rows.length,
    );
  }

  @override
  Future<CreditTopupModel> createTopup(
    String packageId,
    CreditPayMethod method,
  ) async {
    await _wait();
    final pack = CreditMockData.packages.firstWhere(
      (p) => p['id'] == packageId,
      orElse: () => throw const CreditException('CREDIT_PACKAGE_NOT_FOUND'),
    );
    final id = 'mock-${_nextId++}';
    final code = 'RSMOCK${_nextId.toString().padLeft(2, '0')}';
    final order = {
      'id': id,
      'code': code,
      'status': 'PENDING',
      'method': method.apiValue,
      'amountVnd': pack['priceVnd'],
      'credits': pack['credits'],
      'bonusCredits': pack['bonusCredits'],
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'payment': {
        'sandbox': true,
        'payUrl': null,
        'vietQr': method == CreditPayMethod.vietQr
            ? {
                'accountNo': '0000000000',
                'accountName': 'RESTORE DEMO',
                'content': code,
                'imageUrl': '',
              }
            : null,
      },
    };
    _orders[id] = order;
    return CreditTopupModel.fromJson(order);
  }

  Map<String, dynamic> _order(String id) =>
      _orders[id] ?? (throw const CreditException('TOPUP_NOT_FOUND'));

  @override
  Future<CreditTopupModel> getTopup(String id) async {
    await _wait();
    return CreditTopupModel.fromJson(_order(id));
  }

  @override
  Future<void> cancelTopup(String id) async {
    await _wait();
    final order = _order(id);
    if (order['status'] != 'PENDING') {
      throw const CreditException('TOPUP_NOT_PENDING');
    }
    order['status'] = 'FAILED';
  }

  @override
  Future<CreditTopupModel> simulate(String id, {required bool success}) async {
    if (!success) {
      await cancelTopup(id);
      return CreditTopupModel.fromJson(_order(id));
    }
    await _wait();
    final order = _order(id);
    if (order['status'] != 'PENDING') {
      throw const CreditException('TOPUP_NOT_PENDING');
    }
    final now = DateTime.now();
    order['status'] = 'PAID';
    order['paidAt'] = now.toIso8601String();
    final topup = {
      'code': order['code'],
      'method': order['method'],
      'amountVnd': order['amountVnd'],
    };
    final bonus = order['bonusCredits'] as int;
    _ledger.insertAll(0, [
      if (bonus > 0)
        {
          'id': '${id}b',
          'type': 'BONUS',
          'bucket': 'BONUS',
          'amount': bonus,
          'createdAt': now.toIso8601String(),
          'expiresAt': now.add(const Duration(days: 90)).toIso8601String(),
          'topupOrder': topup,
        },
      {
        'id': '${id}t',
        'type': 'TOPUP',
        'bucket': 'PAID',
        'amount': order['credits'],
        'createdAt': now.toIso8601String(),
        'topupOrder': topup,
      },
    ]);
    return CreditTopupModel.fromJson(order);
  }
}

/// Gọi API backend `/credits/*`
class ApiCreditRepository implements CreditRepository {
  ApiCreditRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  /// Chạy [request], đổi lỗi API thành [CreditException] kèm mã lỗi
  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      final body = error.response?.data;
      throw CreditException(body is Map ? body['code'] as String? : null);
    }
  }

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<CreditWallet> getWallet() => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>('/credits/wallet');
    return CreditWallet.fromJson(_data(response));
  });

  @override
  Future<List<CreditPackageModel>> getPackages() => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>('/credits/packages');
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data)
        CreditPackageModel.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  });

  @override
  Future<PagedResult<CreditTransactionModel>> getTransactions({
    int page = 1,
    int limit = CreditRepository.pageSize,
    CreditHistoryFilter filter = CreditHistoryFilter.all,
  }) => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/credits/transactions',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (filter.apiValue != null) 'type': filter.apiValue,
      },
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      CreditTransactionModel.fromJson,
      page: page,
      pageSize: limit,
    );
  });

  @override
  Future<CreditTopupModel> createTopup(
    String packageId,
    CreditPayMethod method,
  ) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/credits/topups',
      data: {'packageId': packageId, 'method': method.apiValue},
    );
    return CreditTopupModel.fromJson(_data(response));
  });

  @override
  Future<CreditTopupModel> getTopup(String id) => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/credits/topups/$id',
    );
    return CreditTopupModel.fromJson(_data(response));
  });

  @override
  Future<void> cancelTopup(String id) => _call(() async {
    await _dio.post<Map<String, dynamic>>('/credits/topups/$id/cancel');
  });

  @override
  Future<CreditTopupModel> simulate(String id, {required bool success}) =>
      _call(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/credits/topups/$id/sandbox',
          data: {'result': success ? 'success' : 'fail'},
        );
        // Giả lập thất bại trả { id, status }, đọc lại đơn cho đủ thông tin
        return success
            ? CreditTopupModel.fromJson(_data(response))
            : getTopup(id);
      });
}
