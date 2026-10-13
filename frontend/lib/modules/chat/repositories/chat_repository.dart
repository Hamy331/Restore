import 'package:restore/core/network/api_client.dart';

/// Nguồn dữ liệu tin nhắn
abstract class ChatRepository {
  /// Tổng số tin nhắn chưa đọc của người dùng, hiện trên thanh điều hướng
  Future<int> getUnreadCount();
}

/// Dữ liệu mẫu, khớp với danh sách cuộc trò chuyện mẫu ở MessagesView
class MockChatRepository implements ChatRepository {
  MockChatRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  @override
  Future<int> getUnreadCount() async {
    await Future<void>.delayed(latency);
    return 3;
  }
}

/// Gọi backend: GET /conversations/unread-count trả về `{ data: { count } }`
class ApiChatRepository implements ChatRepository {
  ApiChatRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations/unread-count',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return (data['count'] as num?)?.toInt() ?? 0;
  }
}
