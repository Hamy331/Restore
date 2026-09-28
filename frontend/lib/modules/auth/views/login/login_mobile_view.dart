import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers/t_snackbar_helper.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/auth_text_field.dart';

class LoginMobileView extends StatefulWidget {
  const LoginMobileView({super.key});

  @override
  State<LoginMobileView> createState() => _LoginMobileViewState();
}

class _LoginMobileViewState extends State<LoginMobileView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          context.read<AuthBloc>().add(LoggedIn());
          context.go('/home');
        }
      },
      builder: (context, state) => AuthScreen(
        title: 'Đăng nhập',
        onBack: () => context.go('/welcome'),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chào mừng trở lại',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 13),
              const Text(
                'Đăng nhập để lưu tin, nhắn tin và đăng bán.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 13),
              AuthTextField(
                label: 'Email',
                hintText: 'email@example.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 13),
              AuthTextField(
                label: 'Mật khẩu',
                hintText: '••••••••',
                controller: _password,
                obscureText: true,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (state is LoginFailure) ...[
                const SizedBox(height: 13),
                AuthFeedback(
                  message: state.error.isEmpty
                      ? 'Email hoặc mật khẩu chưa đúng. Vui lòng thử lại.'
                      : state.error,
                ),
              ],
              const SizedBox(height: 13),
              AppButton(
                label: state is LoginLoading ? 'Đang xử lý…' : 'Đăng nhập',
                isLoading: state is LoginLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 13),
              const AuthDivider(),
              const SizedBox(height: 13),
              AuthGoogleButton(
                onPressed: () => TSnackBarHelper.showInfo(
                  context,
                  message: 'Google Sign-In chưa được kết nối.',
                ),
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản?',
                    style: TextStyle(fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 8),
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 13,
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
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return valid ? null : 'Email chưa đúng định dạng.';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginBloc>().add(
      SubmitLoginEvent(email: _email.text, password: _password.text),
    );
  }
}
