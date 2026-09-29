import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers/t_snackbar_helper.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../bloc/register/register_bloc.dart';
import '../../bloc/register/register_event.dart';
import '../../bloc/register/register_state.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/auth_text_field.dart';

class RegisterMobileView extends StatefulWidget {
  const RegisterMobileView({super.key});

  @override
  State<RegisterMobileView> createState() => _RegisterMobileViewState();
}

class _RegisterMobileViewState extends State<RegisterMobileView> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _acceptedTerms = true;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          context.go('/verify-email?email=${Uri.encodeComponent(_email.text)}');
        }
      },
      builder: (context, state) => AuthScreen(
        title: 'Đăng ký',
        onBack: () => context.go('/welcome'),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo tài khoản ReStore',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Một tài khoản cho cả mua và bán.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              AuthTextField(
                label: 'Họ và tên',
                hintText: 'Tên của bạn',
                controller: _fullName,
              ),
              const SizedBox(height: 10),
              AuthTextField(
                label: 'Email',
                hintText: 'email@example.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 10),
              AuthTextField(
                label: 'Mật khẩu',
                hintText: 'Tối thiểu 8 ký tự',
                controller: _password,
                obscureText: true,
                validator: (value) => value == null || value.length < 8
                    ? 'Mật khẩu cần ít nhất 8 ký tự.'
                    : null,
              ),
              const SizedBox(height: 10),
              AuthTextField(
                label: 'Xác nhận mật khẩu',
                hintText: 'Nhập lại mật khẩu',
                controller: _confirmation,
                obscureText: true,
                validator: (value) => value != _password.text
                    ? 'Mật khẩu xác nhận chưa trùng khớp.'
                    : null,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _acceptedTerms,
                        activeColor: AppColors.primary,
                        checkColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Tôi đồng ý Điều khoản và Chính sách riêng tư',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state is RegisterFailure) ...[
                const SizedBox(height: 10),
                AuthFeedback(message: state.error),
              ],
              const SizedBox(height: 10),
              AppButton(
                label: state is RegisterLoading ? 'Đang xử lý…' : 'Đăng ký',
                isLoading: state is RegisterLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 10),
              const AuthDivider(),
              const SizedBox(height: 10),
              AuthGoogleButton(
                onPressed: () => TSnackBarHelper.showInfo(
                  context,
                  message: 'Google Sign-In chưa được kết nối.',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản?',
                    style: TextStyle(fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 8),
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email.';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? null
        : 'Email chưa đúng định dạng.';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      TSnackBarHelper.showWarning(
        context,
        message: 'Bạn cần đồng ý với điều khoản để tiếp tục.',
      );
      return;
    }
    final username = _email.text.trim().split('@').first;
    context.read<RegisterBloc>().add(
      SubmitRegisterEvent(
        fullName: _fullName.text,
        username: username,
        email: _email.text,
        password: _password.text,
      ),
    );
  }
}
