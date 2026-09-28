import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/auth_text_field.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'phat.ngo@email.com');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScreen(
    title: 'Quên mật khẩu',
    onBack: () => context.go('/login'),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthContextIcon(Icons.lock_reset),
          const SizedBox(height: 13),
          const Text(
            'Đặt lại mật khẩu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          const Text(
            'Nhập email đã đăng ký. ReStore sẽ gửi mã xác minh để bạn tạo mật khẩu mới.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 13),
          AuthTextField(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 13),
          AppButton(label: 'Gửi mã OTP', onPressed: _submit),
          const SizedBox(height: 13),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Nhớ mật khẩu?  Đăng nhập',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.push(
      '/forgot-password/otp?email=${Uri.encodeComponent(_email.text)}',
    );
  }
}
