import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_images.dart';
import 'package:restore/modules/widgets/social_login_button.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../auth_layout.dart';
import '../bloc/login/login_bloc.dart';
import '../bloc/login/login_event.dart';
import '../bloc/login/login_state.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return AuthLayout(
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          } else if (state is LoginSuccess) {
            context.read<AuthBloc>().add(LoggedIn());
            context.go('/home');
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Logo tạm thời
              const FlutterLogo(size: 80),
              const SizedBox(height: 24),

              // 2. Tiêu đề
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.login,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // 3. Form nhập liệu
              CustomTextField(
                label: AppStrings.email,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: AppStrings.password,
                controller: passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 32),

              // 4. Nút đăng nhập
              PrimaryButton(
                text: 'Sign in',
                isLoading: state is LoginLoading,
                onPressed: () {
                  context.read<LoginBloc>().add(
                    SubmitLoginEvent(
                      email: emailController.text,
                      password: passwordController.text,
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // 5. Đường kẻ chia cắt
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or sign in with',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Nút Google
              SocialLoginButton(
                text: 'Google',
                imagePath: AppImages.appLogos.gmailLogo,
                onPressed: () {
                  // Gọi event đăng nhập Google
                },
              ),

              const SizedBox(height: 32),

              // 7. Chuyển hướng đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
