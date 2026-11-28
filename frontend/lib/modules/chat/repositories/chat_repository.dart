import 'dart:async';
import 'chat_realtime.dart';
export 'chat_realtime.dart' show ChatEvent;
import 'dart:math';
import 'dart:typed_data';
import 'package:restore/core/network/media_url.dart';
import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import '../models/chat_models.dart';

/// Nguồn dữ liệu tin nhắn
String newChatClientId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';

abstract class ChatRepository {
  /// Tổng số tin nhắn chưa đọc của người dùng, hiện trên thanh điều hướng
  Future<int> getUnreadCount();

  /// Id của người dùng đang đăng nhập, để phân biệt tin của mình
  Future<String> currentUserId();
  Future<String> startConversation(String recipientId);
  Future<List<ChatConversation>> listConversations();
  Future<ChatConversation> getConversation(String id);
  Future<List<ChatMessage>> getMessages(String id, {int? before, int? after});
  Future<ChatMessage> sendMessage(
    String id,
    String clientId,
    String text, {
    String? listingId,
    int? offerPrice,
  });
  Future<void> markRead(String id, {int? through});

  /// Tên sự kiện realtime (`message`, `presence`…); huỷ lắng nghe sẽ đóng
  /// kết nối.
  Stream<ChatEvent> events();
}

/// Dữ liệu mẫu, khớp với danh sách cuộc trò chuyện mẫu ở MessagesView
class MockChatRepository implements ChatRepository {
  MockChatRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  static const _selfId = 'mock-user';
  final _other = const ChatPerson(id: 'u1', fullName: 'Minh Anh');
  late final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'm1',
      senderId: 'u1',
      text: 'Máy còn bảo hành không bạn?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  ChatConversation get _conversation => ChatConversation(
    id: 'c1',
    otherUser: _other,
    unreadCount: 0,
    lastMessage: _messages.last,
  );

  @override
  Future<int> getUnreadCount() async {
    await Future<void>.delayed(latency);
    return 3;
  }

  @override
  Future<String> currentUserId() async => _selfId;

  @override
  Future<String> startConversation(String recipientId) async => 'c1';

  @override
  Future<List<ChatConversation>> listConversations() async => [_conversation];

  @override
  Future<ChatConversation> getConversation(String id) async => _conversation;

  @override
  Future<List<ChatMessage>> getMessages(
    String id, {
    int? before,
    int? after,
  }) async => before == null && after == null ? List.of(_messages) : [];

  @override
  Future<ChatMessage> sendMessage(
    String id,
    String clientId,
    String text, {
    String? listingId,
    int? offerPrice,
  }) async {
    final message = ChatMessage(
      id: clientId,
      senderId: _selfId,
      text: text,
      createdAt: DateTime.now(),
    );
    _messages.add(message);
    return message;
  }

  @override
  Future<void> markRead(String id, {int? through}) async {}

  @override
  Stream<ChatEvent> events() => const Stream.empty();
}

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<String> currentUserId() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/users/me',
    );
    return (response.data!['data'] as Map)['id'] as String;
  }

  @override
  Future<String> startConversation(
    String recipientId, {
    String? listingId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/conversations',
      data: {
        'recipientId': recipientId,
        if (listingId != null) 'listingId': listingId,
      },
    );
    final data = response.data?['data'];
    final id = data is Map ? data['id'] : null;
    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing conversation id');
    }
    return id;
  }

  @override
  Stream<ChatEvent> events() => ChatRealtime.instance.events;

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations/unread-count',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  @override
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

  @override
  Future<ChatConversation> getConversation(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations/$id',
    );
    return ChatConversation.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String id, {
    int? before,
    int? after,
    bool mediaOnly = false,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/conversations/$id/messages',
      queryParameters: {
        if (before != null) 'before': before,
        if (after != null) 'after': after,
        if (mediaOnly) 'media': '1',
      },
    );
    final rows = (response.data!['data'] as Map)['items'] as List<dynamic>;
    return rows
        .map(
          (row) => ChatMessage.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(
    String id,
    String clientId,
    String text, {
    String? listingId,
    int? offerPrice,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/conversations/$id/messages',
      data: {
        'clientId': clientId,
        'text': text,
        if (listingId != null) 'listingId': listingId,
        if (offerPrice != null) 'offerPrice': offerPrice,
      },
    );
    return ChatMessage.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }

  @override
  Future<void> markRead(String id, {int? through}) async =>
      _apiClient.dio.post<void>(
        '/conversations/$id/read',
        data: {if (through != null) 'through': through},
      );

  Future<ChatMessage> upload(
    String id,
    String clientId,
    Uint8List bytes,
  ) async {
    final response = await _apiClient.dio.post(
      '/conversations/$id/media',
      queryParameters: {'clientId': clientId},
      data: bytes,
      options: Options(
        contentType: 'application/octet-stream',
        sendTimeout: const Duration(minutes: 2),
      ),
    );
    return ChatMessage.fromJson(Map.from(response.data['data'] as Map));
  }

  Future<Uri> mediaLink(String id, String messageId) async {
    final response = await _apiClient.dio.get(
      '/conversations/$id/media/$messageId/link',
    );
    return Uri.parse(resolveMediaUrl(response.data['data']['url'] as String)!);
  }

  Future<List<({String contextId, ChatProduct product})>> discussed(
    String id,
  ) async {
    final response = await _apiClient.dio.get('/conversations/$id/products');
    return [
      for (final row in response.data['data'] as List)
        (
          contextId: row['contextId'] as String,
          product: ChatProduct.fromJson(row)!,
        ),
    ];
  }

  Future<void> preferences(String id, {bool? hidden, bool? blocked}) async {
    await _apiClient.dio.patch(
      '/conversations/$id/preferences',
      data: {
        if (hidden != null) 'hidden': hidden,
        if (blocked != null) 'blocked': blocked,
      },
    );
  }
}
