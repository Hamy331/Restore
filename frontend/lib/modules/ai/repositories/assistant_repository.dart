import 'package:dio/dio.dart';
import 'dart:convert';
import 'stream_adapter.dart'
    if (dart.library.js_interop) 'stream_adapter_web.dart';
import '../../../core/network/api_client.dart';
import '../models/assistant_reply.dart';

class AssistantRepository {
  AssistantRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio {
    configureAssistantStreaming(_dio);
  }
  final Dio _dio;
  Future<AssistantReply> send(
    String conversationId,
    String requestId,
    String message, {
    void Function(Map<String, dynamic>)? onEvent,
    CancelToken? cancelToken,
  }) async {
    if (onEvent != null) {
      final response = await _dio.post<ResponseBody>(
        '/ai/assistant/conversations/$conversationId/messages/stream',
        data: {'requestId': requestId, 'message': message},
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 75),
          headers: {'Accept': 'text/event-stream'},
        ),
      );
      await for (final line
          in response.data!.stream
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final event = jsonDecode(line.substring(5)) as Map<String, dynamic>;
        if (event['type'] == 'done') {
          return AssistantReply.fromJson(
            event['reply'] as Map<String, dynamic>,
          );
        }
        if (event['type'] == 'error') {
          throw AssistantStreamException(
            event['message'] as String? ?? 'AI chưa thể trả lời.',
          );
        }
        onEvent(event);
      }
      throw const AssistantStreamException(
        'Câu trả lời bị ngắt. Bạn có thể thử lại.',
      );
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/assistant/conversations/$conversationId/messages',
      data: {'requestId': requestId, 'message': message},
      options: Options(receiveTimeout: const Duration(seconds: 75)),
    );
    return AssistantReply.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<List<({String id, String title})>> listRecent({String? after}) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/ai/assistant/conversations',
      queryParameters: {'after': ?after},
    );
    return [
      for (final row in r.data!['data'] as List)
        (id: row['id'] as String, title: row['title'] as String),
    ];
  }

  Future<({List<AssistantTurn> turns, Map<String, String> confirmed})> history(
    String id,
  ) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/ai/assistant/conversations/$id',
    );
    final turns = <AssistantTurn>[];
    final confirmed = <String, String>{};
    for (final row in r.data!['data'] as List) {
      final reply = AssistantReply.fromJson(
        row['response'] as Map<String, dynamic>,
      );
      turns.add(
        AssistantTurn(
          id: row['requestId'] as String,
          input: row['input'] as String,
          reply: reply,
        ),
      );
      if (row['confirmed']?['listingId'] case final String listingId) {
        confirmed[reply.draft!['id'] as String] = listingId;
      }
    }
    return (turns: turns, confirmed: confirmed);
  }

  Future<void> remove(String conversationId) async {
    try {
      await _dio.delete<void>('/ai/assistant/conversations/$conversationId');
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
    }
  }
}

class AssistantStreamException implements Exception {
  const AssistantStreamException(this.message);
  final String message;
}
