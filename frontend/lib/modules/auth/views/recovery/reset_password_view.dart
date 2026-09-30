import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_text_field.dart';
import '../../auth_validators.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({required this.resetToken, super.key});
  final String resetToken;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _error;

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
            validator: AuthValidators.password,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 13),
          AuthTextField(
            label: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu mới',
            controller: _confirmation,
            obscureText: true,
            validator: (value) =>
                AuthValidators.confirmation(value, _password.text),
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 13),
          const Text(
            '• 8-72 ký tự, có chữ hoa, chữ thường và số',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 3),
          const Text(
            '• Mật khẩu xác nhận phải trùng khớp',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (_error != null) ...[
            const SizedBox(height: 13),
            AuthFeedback(message: _error!),
          ],
          const SizedBox(height: 26),
          AppButton(
            label: _isLoading ? 'Đang xử lý...' : 'Đặt lại mật khẩu',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _submit,
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authRepository.resetPassword(widget.resetToken, _password.text);
      if (mounted) {
        context.read<AuthBloc>().add(LoggedOut());
        context.go('/password-reset-success');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
