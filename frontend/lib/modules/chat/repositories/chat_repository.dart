import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import '../models/chat_models.dart';

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

  Future<String> startConversation(String recipientId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/conversations',
      data: {'recipientId': recipientId},
    );
    return (response.data!['data'] as Map)['id'] as String;
  }

  Stream<String> events(CancelToken cancelToken) async* {
    final response = await _apiClient.dio.get<ResponseBody>(
      '/conversations/events',
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.stream, receiveTimeout: Duration.zero),
    );
    await for (final line in response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('event:')) yield line.substring(6).trim();
    }
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations/unread-count',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<List<ChatConversation>> listConversations() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations',
    );
    final rows = response.data?['data'] as List<dynamic>? ?? [];
    return rows
        .map(
          (row) =>
              ChatConversation.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<ChatConversation> getConversation(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations/$id',
    );
    return ChatConversation.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }

  Future<List<ChatMessage>> getMessages(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations/$id/messages',
    );
    final rows = (response.data!['data'] as Map)['items'] as List<dynamic>;
    return rows
        .map(
          (row) => ChatMessage.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<ChatMessage> sendMessage(
    String id,
    String clientId,
    String text,
  ) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/conversations/$id/messages',
      data: {'clientId': clientId, 'text': text},
    );
    return ChatMessage.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }

  Future<void> markRead(String id) async =>
      _apiClient.dio.post<void>('/conversations/$id/read');
}
