import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'recaptcha_guard.dart'
    if (dart.library.js_interop) 'recaptcha_guard_web.dart';

/// Lỗi khi gửi / nhập OTP số điện thoại; [code] là mã lỗi đã gom nhóm để
/// hiện câu báo phù hợp.
class PhoneOtpException implements Exception {
  const PhoneOtpException(this.code);

  /// invalid-phone, too-many-requests, invalid-code, expired, unavailable,
  /// app-not-authorized, cancelled (đóng reCAPTCHA), timeout, failed
  final String code;
}

/// Gửi OTP tới số điện thoại và đổi mã người dùng nhập thành ID token để
/// backend xác minh. Chỉ dùng để xác minh số, không thay đăng nhập của app.
abstract class PhoneOtpService {
  /// Nền tảng này có gửi OTP được không (web, Android)
  bool get supported;

  /// Gửi mã tới [phoneE164] (VD +84901234567). Trả ID token luôn nếu
  /// Android tự đọc được mã từ SMS, còn lại trả null để người dùng nhập mã.
  Future<String?> sendCode(String phoneE164);

  /// Nhập đúng [code] thì trả ID token
  Future<String> confirm(String code);

  /// Rời màn xác minh: dọn reCAPTCHA (web)
  void dispose();
}

class FirebasePhoneOtpService implements PhoneOtpService {
  FirebasePhoneOtpService({FirebaseAuth? auth}) : _authOverride = auth;
  final FirebaseAuth? _authOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  ConfirmationResult? _webConfirmation;
  String? _verificationId;
  int? _resendToken;

  @override
  bool get supported =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<String?> sendCode(String phoneE164) async {
    if (!supported) throw const PhoneOtpException('unavailable');
    try {
      if (kIsWeb) {
        _webConfirmation = await _sendOnWeb(phoneE164);
        return null;
      }
      final result = Completer<String?>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        // Android tự đọc mã trong SMS: xác minh luôn, không cần nhập
        verificationCompleted: (credential) async {
          if (result.isCompleted) return;
          try {
            result.complete(await _tokenFor(credential));
          } catch (error) {
            if (!result.isCompleted) result.completeError(error);
          }
        },
        verificationFailed: (error) {
          if (!result.isCompleted) result.completeError(_mapError(error));
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!result.isCompleted) result.complete(null);
        },
        codeAutoRetrievalTimeout: (verificationId) =>
            _verificationId = verificationId,
      );
      return await result.future;
    } on FirebaseAuthException catch (error) {
      throw _mapError(error);
    }
  }

  /// Firebase tự gắn reCAPTCHA ẩn vào trang rồi mới gửi SMS. Người dùng đóng
  /// thử thách thì lời hứa của Firebase không bao giờ xong, nên chạy đua với
  /// [RecaptchaGuard] để báo 'cancelled' / 'timeout' và dọn reCAPTCHA; lần
  /// bấm sau Firebase tạo cái mới.
  Future<ConfirmationResult> _sendOnWeb(String phoneE164) async {
    clearRecaptcha();
    final guard = watchRecaptcha();
    final send = _auth.signInWithPhoneNumber(phoneE164);
    try {
      return await Future.any([
        send,
        guard.aborted.then<ConfirmationResult>(
          (reason) => throw PhoneOtpException(reason),
        ),
      ]);
    } catch (_) {
      // Lời hứa bị bỏ lại có thể báo lỗi muộn: không để thành lỗi chưa bắt
      send.ignore();
      clearRecaptcha();
      rethrow;
    } finally {
      guard.stop();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) clearRecaptcha();
  }

  @override
  Future<String> confirm(String code) async {
    try {
      if (kIsWeb) {
        final confirmation = _webConfirmation;
        if (confirmation == null) throw const PhoneOtpException('expired');
        return await _idTokenOf(await confirmation.confirm(code));
      }
      final id = _verificationId;
      if (id == null) throw const PhoneOtpException('expired');
      return await _tokenFor(
        PhoneAuthProvider.credential(verificationId: id, smsCode: code),
      );
    } on FirebaseAuthException catch (error) {
      throw _mapError(error);
    }
  }

  Future<String> _tokenFor(PhoneAuthCredential credential) async =>
      _idTokenOf(await _auth.signInWithCredential(credential));

  /// Lấy token rồi đăng xuất Firebase ngay: phiên đăng nhập của app vẫn là
  /// JWT của backend, Firebase chỉ dùng để xác minh số.
  Future<String> _idTokenOf(UserCredential credential) async {
    try {
      final token = await credential.user?.getIdToken(true);
      if (token == null) throw const PhoneOtpException('failed');
      return token;
    } finally {
      unawaited(_auth.signOut());
    }
  }

  PhoneOtpException _mapError(FirebaseAuthException error) =>
      PhoneOtpException(switch (error.code) {
        'invalid-phone-number' || 'operation-not-allowed' => 'invalid-phone',
        'too-many-requests' || 'quota-exceeded' => 'too-many-requests',
        'invalid-verification-code' => 'invalid-code',
        'session-expired' ||
        'invalid-verification-id' ||
        'code-expired' => 'expired',
        'app-not-authorized' ||
        'missing-client-identifier' ||
        'captcha-check-failed' ||
        'invalid-app-credential' => 'app-not-authorized',
        _ => 'failed',
      });
}
