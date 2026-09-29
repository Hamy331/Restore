import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_text_field.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScreen(
    title: 'Mật khẩu mới',
    onBack: () => context.pop(),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthContextIcon(Icons.password),
          const SizedBox(height: 13),
          const Text(
            'Tạo mật khẩu mới',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          const Text(
            'Dùng mật khẩu mới, an toàn cho tài khoản ReStore.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 13),
          AuthTextField(
            label: 'Mật khẩu mới',
            hintText: 'Tối thiểu 8 ký tự',
            controller: _password,
            obscureText: true,
            validator: (value) => value == null || value.length < 8
                ? 'Mật khẩu cần ít nhất 8 ký tự.'
                : null,
          ),
          const SizedBox(height: 13),
          AuthTextField(
            label: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu mới',
            controller: _confirmation,
            obscureText: true,
            validator: (value) => value != _password.text
                ? 'Mật khẩu xác nhận chưa trùng khớp.'
                : null,
          ),
          const SizedBox(height: 13),
          const Text(
            '• Ít nhất 8 ký tự',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 3),
          const Text(
            '• Mật khẩu xác nhận phải trùng khớp',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 26),
          AppButton(label: 'Đặt lại mật khẩu', onPressed: _submit),
        ],
      ),
    ),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.go('/password-reset-success');
  }
}
