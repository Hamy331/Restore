import 'dart:async';
import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:restore/core/network/api_client.dart';

class ChatEvent {
  const ChatEvent(this.type, [this.data = const {}]);
  final String type;
  final Map<String, dynamic> data;
}

class ChatRealtime {
  ChatRealtime._();
  static final instance = ChatRealtime._();
  final _events = StreamController<ChatEvent>.broadcast();
  Stream<ChatEvent> get events => _events.stream;
  io.Socket? _socket;
  Timer? _retry;
  int _attempt = 0;
  int _generation = 0;
  String? _user;

  void session(String? id) {
    if (id == _user) return;
    _user = id;
    _generation++;
    _retry?.cancel();
    _socket?.dispose();
    _socket = null;
    _attempt = 0;
    if (id != null) unawaited(_connect(_generation));
  }

  Future<void> _connect(int generation, {bool refresh = false}) async {
    try {
      final api = ApiClient();
      if (refresh && !await api.refreshSession()) {
        throw StateError('session');
      }
      final token = await api.tokenStorage.readAccessToken();
      if (generation != _generation || token == null) return;
      final socket = io.io(Uri.parse(api.dio.options.baseUrl).origin, {
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
        'reconnection': false,
        'auth': {'token': token},
      });
      _socket = socket;
      socket.onConnect((_) {
        _attempt = 0;
        _events.add(const ChatEvent('sync'));
      });
      for (final type in [
        'message.created',
        'conversation.updated',
        'read',
        'seen',
        'trade.updated',
        'presence',
        'sync',
      ]) {
        socket.on(type, (value) {
          if (generation == _generation && value is Map) {
            _events.add(ChatEvent(type, Map<String, dynamic>.from(value)));
          }
        });
      }
      socket.onDisconnect((_) => _schedule(generation));
      socket.onConnectError(
        (error) => _schedule(
          generation,
          refresh: error.toString().contains('AUTH_REQUIRED'),
        ),
      );
      socket.connect();
    } catch (_) {
      _schedule(generation, refresh: refresh);
    }
  }

  void _schedule(int generation, {bool refresh = false}) {
    if (generation != _generation || _retry?.isActive == true) return;
    _retry = Timer(Duration(seconds: min(30, 1 << min(_attempt++, 5))), () {
      if (generation != _generation) return;
      _socket?.clearListeners();
      _socket?.dispose();
      unawaited(_connect(generation, refresh: refresh));
    });
  }
}
