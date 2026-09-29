import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/otp_input.dart';

class ForgotPasswordOtpView extends StatefulWidget {
  const ForgotPasswordOtpView({required this.email, super.key});
  final String email;

  @override
  State<ForgotPasswordOtpView> createState() => _ForgotPasswordOtpViewState();
}

class _ForgotPasswordOtpViewState extends State<ForgotPasswordOtpView> {
  String _otp = '';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final email = widget.email.isEmpty ? 'phat.ngo@email.com' : widget.email;
    return AuthScreen(
      title: 'Xác minh OTP',
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthContextIcon(Icons.mail_lock_outlined),
          const SizedBox(height: 13),
          const Text(
            'Kiểm tra email của bạn',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          Text(
            'Mã OTP đã được gửi đến $email. Nhập 6 chữ số để tiếp tục đặt lại mật khẩu.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 13),
          OtpInput(onChanged: (value) => _otp = value),
          const SizedBox(height: 13),
          const Center(
            child: Text(
              'Mã có hiệu lực trong 05:00',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 13),
            AuthFeedback(message: _error!),
          ],
          const SizedBox(height: 13),
          AppButton(label: 'Xác minh OTP', onPressed: _verify),
          const SizedBox(height: 13),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Chưa nhận được mã?  Gửi lại OTP',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 13),
          const AuthInfoBox(
            message: 'Mã chỉ dùng một lần và hết hạn sau 5 phút.',
          ),
        ],
      ),
    );
  }

  void _verify() {
    if (_otp.length != 6) {
      setState(() => _error = 'Mã OTP không đúng. Kiểm tra và thử lại.');
      return;
    }
    context.push('/reset-password');
  }
}
