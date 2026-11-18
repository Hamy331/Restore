import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/data/models/notification_model.dart';

import '../repositories/notification_repository.dart';

/// Push qua Firebase Cloud Messaging (FCM), dùng cả khi app đang mở lẫn khi
/// app tắt / chạy nền.
///
/// - App tắt / nền: hệ điều hành (Android) hoặc service worker
///   (`web/firebase-messaging-sw.js`) tự hiện thông báo; bấm vào thì mở app và
///   [opened] phát route cần mở.
/// - App đang mở: FCM không tự hiện, [received] phát thông báo để app hiện
///   banner, cập nhật chuông và danh sách.
///
/// Gọi [start] sau khi đăng nhập (người dùng thường), [stop] khi đăng xuất.
class PushMessagingService {
  PushMessagingService({
    required NotificationRepository repository,
    required Future<void> firebaseReady,
  }) : _repository = repository,
       _firebaseReady = firebaseReady;

  final NotificationRepository _repository;
  final Future<void> _firebaseReady;

  final _received = StreamController<PushNotification>.broadcast();
  final _opened = StreamController<PushNotification>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _active = false;
  String? _token;

  /// Thông báo tới khi app đang mở
  Stream<PushNotification> get received => _received.stream;

  /// Người dùng bấm thông báo hệ thống (app được mở từ nền hoặc từ tắt)
  Stream<PushNotification> get opened => _opened.stream;

  /// Có nhận push được trên nền tảng này không
  static bool get isSupported {
    if (AppEnvironment.useMockData) return false;
    if (kIsWeb) return AppEnvironment.fcmVapidKey.isNotEmpty;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String get _platform => kIsWeb
      ? 'web'
      : defaultTargetPlatform == TargetPlatform.iOS
      ? 'ios'
      : 'android';

  /// Xin quyền, lấy token, gửi lên backend và bắt đầu nghe push.
  /// Người dùng từ chối quyền hoặc Firebase lỗi thì thôi (vẫn có chuông trong app).
  Future<void> start() async {
    if (_active || !isSupported) return;
    _active = true;
    try {
      await _firebaseReady;
      if (Firebase.apps.isEmpty || !_active) return;
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (!_active) return;
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push: người dùng chưa cho phép thông báo');
        return;
      }
      _subscriptions
        ..add(
          FirebaseMessaging.onMessage.listen(
            (message) => _emit(_received, message),
          ),
        )
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen(
            (message) => _emit(_opened, message),
          ),
        )
        ..add(messaging.onTokenRefresh.listen(_register));
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? AppEnvironment.fcmVapidKey : null,
      );
      if (token != null) await _register(token);
      // App được mở bằng cách bấm thông báo khi đang tắt
      final initial = await messaging.getInitialMessage();
      if (initial != null) _emit(_opened, initial);
    } catch (error) {
      debugPrint('Push: không bật được FCM: $error');
    }
  }

  Future<void> _register(String token) async {
    if (!_active) return;
    _token = token;
    try {
      await _repository.registerPushDevice(token, _platform);
    } catch (error) {
      debugPrint('Push: không lưu được token: $error');
    }
  }

  /// Đăng xuất: ngừng nghe và huỷ token (máy này không nhận push của tài khoản cũ nữa)
  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      // Phiên có thể đã hết; backend tự xoá token hỏng ở lần gửi sau
      await _repository.unregisterPushDevice(token);
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Push: không huỷ được token: $error');
    }
  }

  void _emit(StreamController<PushNotification> sink, RemoteMessage message) {
    final push = PushNotification.fromRemote(message);
    if (push != null && !sink.isClosed) sink.add(push);
  }

  /// Test: giả lập một push tới khi app đang mở
  @visibleForTesting
  void addReceivedForTest(PushNotification push) => _received.add(push);

  Future<void> dispose() async {
    await stop();
    await _received.close();
    await _opened.close();
  }
}

/// Nội dung một push thông báo (xem notification.push.ts ở backend)
class PushNotification {
  const PushNotification({
    required this.notification,
    required this.unreadCount,
  });

  /// Thông báo dựng lại từ push, để hiện banner bằng câu chữ theo ngôn ngữ app
  final NotificationModel notification;

  /// Số chưa đọc của người nhận lúc gửi (cho chấm đỏ)
  final int? unreadCount;

  String? get link => notification.link;

  static PushNotification? fromRemote(RemoteMessage message) => fromData(
    message.data,
    message.notification?.title,
    message.notification?.body,
  );

  /// [data] là phần data của push FCM (giá trị đều là chuỗi)
  static PushNotification? fromData(
    Map<String, dynamic> data, [
    String? title,
    String? body,
  ]) {
    if (data['kind'] != 'notification' || data['notificationId'] == null) {
      return null;
    }
    Object? payload;
    try {
      payload = jsonDecode(data['payload'] as String? ?? '{}');
    } catch (_) {
      payload = null;
    }
    final link = data['link'] as String?;
    return PushNotification(
      notification: NotificationModel.fromJson({
        'id': data['notificationId'],
        'type': data['type'],
        'group': data['group'],
        'title': title ?? '',
        'body': body ?? '',
        'data': payload is Map ? payload : const <String, dynamic>{},
        'link': link == null || link.isEmpty ? null : link,
        'readAt': null,
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
      }),
      unreadCount: int.tryParse(data['unreadCount'] as String? ?? ''),
    );
  }
}
