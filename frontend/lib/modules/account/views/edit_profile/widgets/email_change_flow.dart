import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';

import '../../../bloc/user_profile/user_profile_cubit.dart';
import '../../../repositories/profile_repository.dart';

/// Mở bảng đổi email (hộp thoại trên màn rộng, bottom sheet trên điện thoại).
/// Trả email mới khi đổi xong, null nếu đóng giữa chừng.
Future<String?> showEmailChangeFlow(
  BuildContext context,
  UserProfileCubit cubit,
) {
  final flow = EmailChangeFlow(cubit: cubit);
  if (isDesktopLayout(context)) {
    return showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: flow,
        ),
      ),
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: flow,
    ),
  );
}

/// Hai bước: (1) email mới + mật khẩu hiện tại → gửi mã tới email mới,
/// (2) nhập mã 6 số → đổi email. Có đếm ngược trước khi gửi lại mã.
class EmailChangeFlow extends StatefulWidget {
  const EmailChangeFlow({super.key, required this.cubit});
  final UserProfileCubit cubit;

  @override
  State<EmailChangeFlow> createState() => _EmailChangeFlowState();
}

class _EmailChangeFlowState extends State<EmailChangeFlow> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  bool _codeSent = false, _busy = false, _hidePassword = true;
  String? _error;
  int _wait = 0;
  Timer? _timer;

  bool get _vi => Localizations.localeOf(context).languageCode == 'vi';
  String _t(String vn, String en) => _vi ? vn : en;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _countdown(int seconds) {
    _timer?.cancel();
    setState(() => _wait = seconds);
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
    if (error is ProfileUpdateException && error.message != null) {
      return error.message!;
    }
    return _t(
      'Không thực hiện được lúc này. Vui lòng thử lại.',
      'Something went wrong. Please try again.',
    );
  }

  Future<void> _send() async {
    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(
        () => _error = _t('Email chưa đúng định dạng.', 'Enter a valid email.'),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final wait = await widget.cubit.requestEmailChange(email, _password.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _countdown(wait);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_otp.text.length != 6) {
      setState(
        () => _error = _t(
          'Mã OTP phải gồm đúng 6 chữ số.',
          'The code has 6 digits.',
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = await widget.cubit.verifyEmailChange(_otp.text);
      if (mounted) Navigator.of(context).pop(email);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final email = _email.text.trim().toLowerCase();
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t('Đổi email', 'Change email'),
              style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _codeSent
                  ? _t(
                      'Nhập mã 6 số vừa gửi tới $email. Mã hết hạn sau 5 phút.',
                      'Enter the 6-digit code sent to $email. It expires in 5 minutes.',
                    )
                  : _t(
                      'Mã xác nhận sẽ được gửi tới email mới. Email chỉ đổi khi bạn nhập đúng mã.',
                      'We will send a code to the new email. It changes only after you enter the code.',
                    ),
              style: theme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            if (!_codeSent) ...[
              TextField(
                key: const ValueKey('email-change-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: _t('Email mới', 'New email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('email-change-password'),
                controller: _password,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _busy ? null : _send(),
                decoration: InputDecoration(
                  labelText: _t('Mật khẩu hiện tại', 'Current password'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ] else
              TextField(
                key: const ValueKey('email-change-otp'),
                controller: _otp,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _busy ? null : _verify(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                  border: const OutlineInputBorder(),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                key: const ValueKey('email-change-error'),
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const ValueKey('email-change-submit'),
              onPressed: _busy ? null : (_codeSent ? _verify : _send),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _codeSent
                          ? _t('Xác nhận', 'Confirm')
                          : _t('Gửi mã', 'Send code'),
                    ),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 6),
              // Màn hẹp / chữ lớn thì hai nút tự xuống dòng thay vì tràn
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _codeSent = false;
                            _otp.clear();
                            _error = null;
                          }),
                    child: Text(_t('Đổi email khác', 'Use another email')),
                  ),
                  TextButton(
                    key: const ValueKey('email-change-resend'),
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
          ],
        ),
      ),
    );
  }
}
