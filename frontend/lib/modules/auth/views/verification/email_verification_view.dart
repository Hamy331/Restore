import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/otp_input.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({required this.email, super.key});
  final String email;

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  String _otp = '';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final email = widget.email.isEmpty ? 'phat.ngo@email.com' : widget.email;
    return AuthScreen(
      title: 'Xác minh email',
      onBack: () => context.go('/register'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthContextIcon(Icons.mark_email_unread_outlined),
          const SizedBox(height: 13),
          const Text(
            'Nhập mã xác minh',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          Text(
            'Mã OTP đã được gửi đến $email. Kiểm tra hộp thư và nhập 6 chữ số bên dưới.',
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
              'Mã có hiệu lực trong 04:42',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 13),
            AuthFeedback(message: _error!),
          ],
          const SizedBox(height: 13),
          AppButton(label: 'Xác minh email', onPressed: _verify),
          const SizedBox(height: 13),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Chưa nhận được mã?  Gửi lại sau 00:42',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 13),
          const AuthInfoBox(
            message: 'Bạn có thể tiếp tục xem tin sau khi xác minh email.',
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
    context.go('/email-verified');
  }
}
