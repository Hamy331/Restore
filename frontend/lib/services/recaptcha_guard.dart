import 'dart:async';

/// Ngoài web không có reCAPTCHA: không bao giờ huỷ, không có gì để dọn.
class RecaptchaGuard {
  final _never = Completer<String>();

  /// Không bao giờ hoàn tất ngoài web
  Future<String> get aborted => _never.future;

  void stop() {}
}

RecaptchaGuard watchRecaptcha() => RecaptchaGuard();

void clearRecaptcha() {}
