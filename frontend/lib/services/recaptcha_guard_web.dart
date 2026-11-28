import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Khung Firebase tự gắn vào trang cho reCAPTCHA ẩn (chứa cả badge
/// "protected by reCAPTCHA").
const _containerId = '__ff-recaptcha-container';

/// iframe chứa thử thách (chọn ảnh) của reCAPTCHA
const _challengeFrames =
    'iframe[src*="/recaptcha/api2/bframe"],'
    'iframe[src*="/recaptcha/enterprise/bframe"]';

/// Chưa hiện thử thách mà quá lâu vẫn chưa gửi được mã thì coi như hỏng
const _idleLimit = Duration(seconds: 30);

/// Thử thách hết hạn sau 2 phút; quá mức này thì thôi chờ
const _hardLimit = Duration(minutes: 3);

/// Theo dõi reCAPTCHA trong lúc gửi mã: reCAPTCHA không báo gì khi người dùng
/// đóng thử thách (bấm ra ngoài), nên lời hứa của Firebase treo mãi. Lớp này
/// dò khung thử thách để báo [aborted] là 'cancelled' (đóng mà chưa giải) hoặc
/// 'timeout' (chờ quá lâu).
class RecaptchaGuard {
  RecaptchaGuard() {
    _timer = Timer.periodic(const Duration(milliseconds: 300), _tick);
  }

  final _aborted = Completer<String>();
  final _started = DateTime.now();
  late final Timer _timer;
  DateTime? _idleSince = DateTime.now();
  bool _seenOpen = false;

  /// Hoàn tất với 'cancelled' hoặc 'timeout'; không hoàn tất nếu mọi việc ổn
  Future<String> get aborted => _aborted.future;

  void stop() => _timer.cancel();

  void _abort(String reason) {
    stop();
    if (!_aborted.isCompleted) _aborted.complete(reason);
  }

  void _tick(Timer _) {
    if (_solved()) {
      // Đã giải xong: Firebase đang gửi SMS, để nó tự báo kết quả / lỗi
      stop();
      return;
    }
    final now = DateTime.now();
    if (now.difference(_started) > _hardLimit) return _abort('timeout');
    if (_challengeOpen()) {
      _seenOpen = true;
      _idleSince = null;
      return;
    }
    if (_seenOpen) {
      // Thử thách vừa đóng mà chưa có mã trả lời → người dùng đã tắt nó.
      // Chờ thêm một nhịp cho chắc reCAPTCHA chưa kịp ghi mã trả lời.
      _seenOpen = false;
      _idleSince = null;
      Timer(const Duration(milliseconds: 400), () {
        if (_aborted.isCompleted || !_timer.isActive) return;
        if (_solved()) return stop();
        if (!_challengeOpen()) _abort('cancelled');
      });
      return;
    }
    final idleSince = _idleSince ??= now;
    if (now.difference(idleSince) > _idleLimit) _abort('timeout');
  }
}

RecaptchaGuard watchRecaptcha() => RecaptchaGuard();

/// Gỡ reCAPTCHA (cả badge và khung thử thách) khỏi trang. Lần gửi sau Firebase
/// tạo cái mới.
void clearRecaptcha() {
  web.document.getElementById(_containerId)?.remove();
  for (final frame in _frames()) {
    _overlayOf(frame)?.remove();
  }
}

/// Mã trả lời reCAPTCHA đã có (người dùng giải xong / không cần thử thách)
bool _solved() {
  final answer = web.document.querySelector(
    '#$_containerId textarea[name="g-recaptcha-response"]',
  );
  return answer != null &&
      answer.isA<web.HTMLTextAreaElement>() &&
      (answer as web.HTMLTextAreaElement).value.isNotEmpty;
}

/// Có khung thử thách nào đang hiện không
bool _challengeOpen() => _frames().any((frame) {
  final overlay = _overlayOf(frame);
  return overlay != null &&
      web.window.getComputedStyle(overlay).visibility == 'visible';
});

Iterable<web.Node> _frames() sync* {
  final list = web.document.querySelectorAll(_challengeFrames);
  for (var i = 0; i < list.length; i++) {
    final node = list.item(i);
    if (node != null) yield node;
  }
}

/// Khối ngoài cùng (con trực tiếp của body) bọc khung thử thách: reCAPTCHA
/// bật / tắt thuộc tính visibility của khối này khi mở / đóng thử thách.
web.Element? _overlayOf(web.Node frame) {
  var element = frame.parentElement;
  while (element != null) {
    final parent = element.parentElement;
    if (parent == null || parent.tagName == 'BODY') return element;
    element = parent;
  }
  return null;
}
