import 'package:equatable/equatable.dart';

/// Số tin nháp đang giữ so với giới hạn của gói, nhận từ API
/// `GET /listings/drafts/quota`. Gói Cá nhân 3, Cửa hàng Basic 10, Pro 30
/// (backend quyết định, admin chỉnh được trong gói).
class DraftQuota extends Equatable {
  final int used;
  final int limit;

  const DraftQuota({required this.used, required this.limit});

  /// Giới hạn mặc định của tài khoản cá nhân (dữ liệu mẫu)
  static const int personalLimit = 3;

  int get remaining => (limit - used).clamp(0, limit);
  bool get isFull => used >= limit;

  factory DraftQuota.fromJson(Map<String, dynamic> json) => DraftQuota(
    used: (json['used'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num).toInt(),
  );

  @override
  List<Object?> get props => [used, limit];
}

/// Đã giữ đủ số tin nháp của gói (API trả 409 `DRAFT_LIMIT_REACHED`)
class DraftLimitReachedException implements Exception {
  const DraftLimitReachedException();

  static const String code = 'DRAFT_LIMIT_REACHED';
}
