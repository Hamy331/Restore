import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_images.dart';
import 'package:restore/core/constants/app_strings.dart';
import 'package:restore/modules/auth/auth_layout.dart';
import 'package:restore/modules/auth/bloc/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth_event.dart';
import 'package:restore/modules/auth/bloc/login/login_bloc.dart';
import 'package:restore/modules/auth/bloc/login/login_event.dart';
import 'package:restore/modules/auth/bloc/login/login_state.dart';
import 'package:restore/modules/widgets/social_login_button.dart';
import 'package:restore/shared/widgets/custom_text_field.dart';
import 'package:restore/shared/widgets/primary_button.dart';

class LoginMobileView extends StatelessWidget {
  const LoginMobileView({super.key});

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
              FlutterLogo(size: 80.w),
              SizedBox(height: 24.h),

              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.login,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 40.h),

              CustomTextField(
                label: AppStrings.email,
                controller: emailController,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: AppStrings.password,
                controller: passwordController,
                isPassword: true,
              ),
              SizedBox(height: 32.h),

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

              SizedBox(height: 32.h),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'Or sign in with',
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              SizedBox(height: 24.h),

              SocialLoginButton(
                text: 'Google',
                imagePath: AppImages.appLogos.gmailLogo,
                onPressed: () {},
              ),

              SizedBox(height: 32.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
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
