import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/ai/repositories/assistant_repository.dart';

class StreamAdapter implements HttpClientAdapter {
  StreamAdapter(this.controller);
  final StreamController<Uint8List> controller;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, endsWith('/messages/stream'));
    return ResponseBody(
      controller.stream,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('repository emits fragmented UTF-8 events before final reply', () async {
    final controller = StreamController<Uint8List>();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = StreamAdapter(controller);
    final repository = AssistantRepository(dio: dio);
    final progress = Completer<void>();
    final reply = repository.send(
      'conversation',
      'request',
      'hello',
      onEvent: (event) {
        expect(event['text'], 'Tiếng Việt');
        progress.complete();
      },
    );
    final bytes = utf8.encode(
      'data: ${jsonEncode({'type': 'delta', 'text': 'Tiếng Việt'})}\n\n',
    );
    for (final byte in bytes) {
      controller.add(Uint8List.fromList([byte]));
    }
    await progress.future.timeout(const Duration(seconds: 3));
    controller.add(
      Uint8List.fromList(
        utf8.encode(
          'data: ${jsonEncode({
            'type': 'done',
            'reply': {'text': 'Xong', 'listings': [], 'sources': []},
          })}\n\n',
        ),
      ),
    );
    expect((await reply).text, 'Xong');
    await controller.close();
    dio.close();
  });
}
