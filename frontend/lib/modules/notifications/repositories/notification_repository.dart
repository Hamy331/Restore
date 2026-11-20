import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/notification_mock_data.dart';
import '../models/notification_filter.dart';

/// Thông báo trong app. Hợp đồng API: `/notifications`.
abstract class NotificationRepository {
  static const int pageSize = 20;

  /// Thông báo của tôi, mới trước, [page] bắt đầu từ 1
  Future<PagedResult<NotificationModel>> getNotifications({
    int page = 1,
    int limit = pageSize,
    NotificationFilter filter = NotificationFilter.all,
  });

  /// Số chưa đọc (chấm đỏ trên chuông)
  Future<int> getUnreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();

  Future<void> delete(String id);

  /// Lưu token push (FCM) của thiết bị này cho người đang đăng nhập.
  /// [platform]: android | ios | web
  Future<void> registerPushDevice(String token, String platform);

  /// Gỡ token push của thiết bị này
  Future<void> unregisterPushDevice(String token);
}

/// Dữ liệu mẫu giữ trong bộ nhớ (đọc / xoá còn nguyên khi mở lại trang)
class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({
    this.latency = const Duration(milliseconds: 300),
  });

  final Duration latency;

  static List<Map<String, dynamic>>? _rows;

  /// Xoá dữ liệu đã đổi (dùng trong test)
  static void reset() => _rows = null;

  List<Map<String, dynamic>> get _all =>
      _rows ??= NotificationMockData.notifications(DateTime.now());

  Future<void> _wait() => Future<void>.delayed(latency);

  bool _matches(Map<String, dynamic> row, NotificationFilter filter) {
    if (filter.unreadOnly) return row['readAt'] == null;
    final group = filter.group;
    return group == null || row['group'] == group.apiValue;
  }

  @override
  Future<PagedResult<NotificationModel>> getNotifications({
    int page = 1,
    int limit = NotificationRepository.pageSize,
    NotificationFilter filter = NotificationFilter.all,
  }) async {
    await _wait();
    final rows = [
      for (final row in _all)
        if (_matches(row, filter)) row,
    ];
    final start = (page - 1) * limit;
    return PagedResult(
      items: [
        for (final row in rows.skip(start).take(limit))
          NotificationModel.fromJson(row),
      ],
      page: page,
      hasMore: start + limit < rows.length,
      totalItems: rows.length,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    await _wait();
    return _all.where((row) => row['readAt'] == null).length;
  }

  @override
  Future<void> markRead(String id) async {
    await _wait();
    for (final row in _all) {
      if (row['id'] == id) row['readAt'] ??= DateTime.now().toIso8601String();
    }
  }

  @override
  Future<void> markAllRead() async {
    await _wait();
    final now = DateTime.now().toIso8601String();
    for (final row in _all) {
      row['readAt'] ??= now;
    }
  }

  @override
  Future<void> delete(String id) async {
    await _wait();
    _all.removeWhere((row) => row['id'] == id);
  }

  /// Dữ liệu mẫu không có push
  @override
  Future<void> registerPushDevice(String token, String platform) async {}

  @override
  Future<void> unregisterPushDevice(String token) async {}
}

/// Gọi API backend `/notifications`
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  @override
  Future<PagedResult<NotificationModel>> getNotifications({
    int page = 1,
    int limit = NotificationRepository.pageSize,
    NotificationFilter filter = NotificationFilter.all,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (filter.group != null) 'group': filter.group!.apiValue,
        if (filter.unreadOnly) 'unread': true,
      },
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      NotificationModel.fromJson,
      page: page,
      pageSize: limit,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications/unread-count',
    );
    final data = response.data?['data'];
    return data is Map && data['count'] is num
        ? (data['count'] as num).toInt()
        : 0;
  }

  @override
  Future<void> markRead(String id) =>
      _dio.post<void>('/notifications/$id/read');

  @override
  Future<void> markAllRead() => _dio.post<void>('/notifications/read-all');

  @override
  Future<void> delete(String id) => _dio.delete<void>('/notifications/$id');

  @override
  Future<void> registerPushDevice(String token, String platform) =>
      _dio.post<void>(
        '/notifications/devices',
        data: {'token': token, 'platform': platform},
      );

  @override
  Future<void> unregisterPushDevice(String token) =>
      _dio.delete<void>('/notifications/devices', data: {'token': token});
}
