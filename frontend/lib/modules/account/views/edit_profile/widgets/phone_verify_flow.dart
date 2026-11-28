import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/helpers/phone_number.dart';
import 'package:restore/services/phone_otp_service.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';

import '../../../bloc/user_profile/user_profile_cubit.dart';
import '../../../repositories/phone_verification_repository.dart';
import '../../../repositories/profile_repository.dart';

/// Mở màn thêm / đổi / xác minh số điện thoại bằng OTP: trang toàn màn hình
/// trên điện thoại, hộp thoại trên màn rộng. [phone] (dạng 0901234567) điền
/// sẵn ô nhập số. Trả số đã xác minh, null nếu đóng giữa chừng.
Future<String?> showPhoneVerifyFlow(
  BuildContext context,
  UserProfileCubit cubit,
  String? phone, {
  PhoneOtpService? otp,
  PhoneVerificationRepository? repository,
}) {
  final flow = PhoneVerifyFlow(
    cubit: cubit,
    phone: phone,
    otp: otp ?? FirebasePhoneOtpService(),
    repository: repository ?? PhoneVerificationRepository(),
  );
  if (isDesktopLayout(context)) {
    return showDialog<String>(
      context: context,
      // Màn rộng: hộp thoại giữa màn hình, cao theo màn (tối đa 600)
      builder: (dialog) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 480,
          height: (MediaQuery.sizeOf(dialog).height - 48).clamp(420, 600),
          child: flow,
        ),
      ),
    );
  }
  return Navigator.of(context).push<String>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => flow),
  );
}

/// Hai bước: (1) nhập số (+84) và nhận mã qua SMS, (2) nhập mã 6 số → backend
/// xác minh và lưu số. Có đếm ngược trước khi gửi lại mã.
class PhoneVerifyFlow extends StatefulWidget {
  const PhoneVerifyFlow({
    super.key,
    required this.cubit,
    this.phone,
    required this.otp,
    required this.repository,
  });
  final UserProfileCubit cubit;
  final String? phone;
  final PhoneOtpService otp;
  final PhoneVerificationRepository repository;

  @override
  State<PhoneVerifyFlow> createState() => _PhoneVerifyFlowState();
}

class _PhoneVerifyFlowState extends State<PhoneVerifyFlow> {
  static const _resendSeconds = 60;

  /// Ô nhập chỉ giữ phần sau +84 (0901234567 → 901234567)
  late final _phone = TextEditingController(
    text: (widget.phone ?? '').replaceFirst(RegExp('^0'), ''),
  );
  final _code = TextEditingController();

  /// Số đã gửi mã (dạng 0901234567)
  String _sentTo = '';
  bool _codeSent = false, _busy = false;
  String? _error;
  int _wait = 0;
  Timer? _timer;

  bool get _vi => Localizations.localeOf(context).languageCode == 'vi';
  String _t(String vn, String en) => _vi ? vn : en;

  @override
  void dispose() {
    _timer?.cancel();
    widget.otp.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _countdown() {
    _timer?.cancel();
    setState(() => _wait = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _wait <= 1) {
        timer.cancel();
        if (mounted) setState(() => _wait = 0);
        return;
      }
      setState(() => _wait--);
    });
  }

  String _message(Object error) {
    if (error is PhoneOtpException) {
      return switch (error.code) {
        'invalid-phone' => _t(
          'Số điện thoại không nhận được mã. Kiểm tra lại số.',
          'This number cannot receive a code. Check the number.',
        ),
        'too-many-requests' => _t(
          'Bạn đã yêu cầu quá nhiều lần. Vui lòng thử lại sau.',
          'Too many attempts. Please try again later.',
        ),
        'invalid-code' => _t(
          'Mã không đúng. Kiểm tra lại tin nhắn.',
          'Wrong code. Check the message again.',
        ),
        'expired' => _t(
          'Mã đã hết hạn. Bấm Gửi lại mã.',
          'The code expired. Tap Resend code.',
        ),
        'unavailable' => _t(
          'Thiết bị này chưa hỗ trợ xác minh. Hãy xác minh trên điện thoại Android hoặc trang web.',
          'Verification is not available here. Use the Android app or the website.',
        ),
        'timeout' => _t(
          'Quá lâu chưa gửi được mã. Vui lòng thử lại.',
          'Sending the code took too long. Please try again.',
        ),
        'app-not-authorized' => _t(
          'Ứng dụng chưa được cấp quyền gửi mã. Vui lòng thử lại sau.',
          'The app is not allowed to send codes yet. Please try again later.',
        ),
        _ => _t(
          'Không gửi được mã lúc này. Vui lòng thử lại.',
          'Could not send the code. Please try again.',
        ),
      };
    }
    if (error is ProfileUpdateException && error.message != null) {
      return error.message!;
    }
    return _t(
      'Không thực hiện được lúc này. Vui lòng thử lại.',
      'Something went wrong. Please try again.',
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on PhoneOtpException catch (error) {
      // Người dùng tự đóng reCAPTCHA: chỉ trả nút về như cũ, không báo lỗi
      if (mounted && error.code != 'cancelled') {
        setState(() => _error = _message(error));
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Số trong ô (sau +84) đổi về dạng 0901234567; null nếu chưa hợp lệ
  String? get _typedPhone {
    final digits = _phone.text.replaceAll(RegExp(r'[\s.\-()]'), '');
    if (digits.isEmpty) return null;
    final local = normalizePhone(
      digits.startsWith('0') || digits.startsWith('84') && digits.length == 11
          ? digits
          : '0$digits',
    );
    return local == null || local.isEmpty ? null : local;
  }

  /// 0901234567 → +84 901 234 567
  String _display(String phone) {
    final d = phone.substring(1);
    return '+84 ${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
  }

  Future<void> _send() {
    final phone = _typedPhone;
    if (phone == null) {
      setState(
        () => _error = _t(
          'Số điện thoại không hợp lệ (VD 901 234 567).',
          'Invalid mobile number (e.g. 901 234 567).',
        ),
      );
      return Future.value();
    }
    return _run(() async {
      // 0901234567 → +84901234567
      final token = await widget.otp.sendCode('+84${phone.substring(1)}');
      if (!mounted) return;
      // Android tự đọc được mã trong SMS: xác minh luôn
      if (token != null) return _finish(token);
      setState(() {
        _codeSent = true;
        _sentTo = phone;
        _code.clear();
      });
      _countdown();
    });
  }

  Future<void> _confirm() {
    if (_code.text.length != 6) {
      setState(
        () => _error = _t('Mã gồm đúng 6 chữ số.', 'The code has 6 digits.'),
      );
      return Future.value();
    }
    return _run(() async => _finish(await widget.otp.confirm(_code.text)));
  }

  Future<void> _finish(String idToken) async {
    final phone = await widget.repository.verify(idToken);
    widget.cubit.markPhoneVerified(phone);
    if (mounted) Navigator.of(context).pop(phone);
  }

  InputDecoration _boxDecoration({String? hint, Widget? prefix}) =>
      InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final canSend = !_busy && _typedPhone != null;
    final canConfirm = !_busy && _code.text.length == 6;
    final adding = (widget.phone ?? '').isEmpty;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const ValueKey('phone-verify-close'),
          tooltip: _t('Đóng', 'Close'),
          icon: const Icon(Icons.close),
          // Luôn đóng được, kể cả khi đang chờ reCAPTCHA / gửi mã
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _codeSent
                          ? _t('Nhập mã xác minh', 'Enter verification code')
                          : adding
                          ? _t('Thêm số điện thoại', 'Add mobile number')
                          : _t(
                              'Cập nhật số điện thoại',
                              'Update mobile number',
                            ),
                      style: theme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_codeSent) ...[
                      TextField(
                        key: const ValueKey('phone-verify-number'),
                        controller: _phone,
                        autofocus: adding,
                        keyboardType: TextInputType.phone,
                        maxLength: 13,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[0-9 ]')),
                        ],
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => canSend ? _send() : null,
                        style: const TextStyle(fontSize: 17),
                        decoration: _boxDecoration(
                          hint: _t('Số điện thoại', 'Mobile number'),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 14, right: 8),
                            child: Text(
                              '🇻🇳  +84',
                              style: TextStyle(fontSize: 17),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _t('Nhận mã OTP qua', 'Receive OTP through'),
                        style: theme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ChoiceChip(
                          key: const ValueKey('phone-verify-sms'),
                          label: const Text('SMS'),
                          selected: true,
                          showCheckmark: false,
                          onSelected: (_) {},
                        ),
                      ),
                    ] else ...[
                      Text(
                        _t(
                          'Mã 6 số đã gửi tới ${_display(_sentTo)}.',
                          'We sent a 6-digit code to ${_display(_sentTo)}.',
                        ),
                        style: theme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const ValueKey('phone-verify-code'),
                        controller: _code,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => canConfirm ? _confirm() : null,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, letterSpacing: 8),
                        decoration: _boxDecoration(hint: '••••••'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _codeSent = false;
                                    _code.clear();
                                    _error = null;
                                  }),
                            child: Text(
                              _t('Đổi số khác', 'Use another number'),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('phone-verify-resend'),
                            onPressed: _busy || _wait > 0 ? null : _send,
                            child: Text(
                              _wait > 0
                                  ? _t(
                                      'Gửi lại mã sau ${_wait}s',
                                      'Resend in ${_wait}s',
                                    )
                                  : _t('Gửi lại mã', 'Resend code'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        key: const ValueKey('phone-verify-error'),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const ValueKey('phone-verify-submit'),
                    onPressed: _codeSent
                        ? (canConfirm ? _confirm : null)
                        : (canSend ? _send : null),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _codeSent
                                ? _t('Xác nhận', 'Confirm')
                                : _t(
                                    'Nhận mã xác minh',
                                    'Get verification code',
                                  ),
                          ),
                  ),
                  if (!_codeSent) ...[
                    const SizedBox(height: 12),
                    Text(
                      _t(
                        'Khi bấm "Nhận mã xác minh", bạn đồng ý để ReStore gửi tin nhắn SMS chứa mã xác minh tới số này.',
                        'By tapping "Get verification code", you allow ReStore to send you an SMS message for verification.',
                      ) +
                      // Web ẩn badge reCAPTCHA (để không che nút, xem
                      // web/index.html) nên phải ghi rõ ở đây
                      (kIsWeb
                          ? _t(
                              ' Trang được bảo vệ bởi reCAPTCHA, áp dụng Chính sách quyền riêng tư và Điều khoản dịch vụ của Google.',
                              ' This site is protected by reCAPTCHA and the Google Privacy Policy and Terms of Service apply.',
                            )
                          : ''),
                      style: theme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
