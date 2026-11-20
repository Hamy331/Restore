import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

// Browser XMLHttpRequest buffers SSE. Use Fetch only for the AI stream route;
// keep the shared Dio interceptors (including refresh-token retries) intact.
void configureAssistantStreaming(Dio dio) {
  if (dio.httpClientAdapter is! _AssistantFetchAdapter) {
    dio.httpClientAdapter = _AssistantFetchAdapter(dio.httpClientAdapter);
  }
}

class _AssistantFetchAdapter implements HttpClientAdapter {
  _AssistantFetchAdapter(this.delegate);
  final HttpClientAdapter delegate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.responseType != ResponseType.stream ||
        !options.path.endsWith('/messages/stream')) {
      return delegate.fetch(options, requestStream, cancelFuture);
    }
    final abort = web.AbortController();
    cancelFuture?.then((_) => abort.abort());
    final headers = web.Headers();
    options.headers.forEach((key, value) => headers.set(key, value.toString()));
    final bytes =
        await requestStream?.fold<List<int>>(
          [],
          (all, chunk) => all..addAll(chunk),
        ) ??
        [];
    final response = await web.window
        .fetch(
          options.uri.toString().toJS,
          web.RequestInit(
            method: options.method,
            headers: headers,
            body: utf8.decode(bytes).toJS,
            signal: abort.signal,
          ),
        )
        .toDart
        .timeout(
          options.connectTimeout ?? const Duration(seconds: 30),
          onTimeout: () {
            abort.abort();
            throw TimeoutException('Connection timed out');
          },
        );
    Stream<Uint8List> read() async* {
      final body = response.body;
      if (body == null) return;
      final reader = body.getReader() as web.ReadableStreamDefaultReader;
      try {
        while (true) {
          final item = await reader.read().toDart;
          if (item.done) break;
          yield (item.value as JSUint8Array).toDart;
        }
      } finally {
        abort.abort();
        reader.releaseLock();
      }
    }

    return ResponseBody(
      read().timeout(options.receiveTimeout ?? const Duration(seconds: 75)),
      response.status,
      headers: {
        Headers.contentTypeHeader: [
          response.headers.get('content-type') ?? 'text/event-stream',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) => delegate.close(force: force);
}
