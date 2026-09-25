import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/shared/widgets/primary_button.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/utils/helpers/t_snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth_layout.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';
import '../../../widgets/social_login_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';


class LoginMobileView extends StatelessWidget {
  const LoginMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return AuthLayout(
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            // Thay thế ScaffoldMessenger cũ bằng Helper Lỗi
            TSnackBarHelper.showError(
              context,
              message: state.error.isNotEmpty
                  ? state.error
                  : l10n.loginErrorMsg,
            );
          } else if (state is LoginSuccess) {
            // Sử dụng Helper Thành công, bỏ qua title để nó tự lấy l10n.successTitle
            TSnackBarHelper.showSuccess(context, message: l10n.loginSuccessMsg);
            context.read<AuthBloc>().add(LoggedIn());
            context.go('/home');
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.appLogos.appLogo,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24.h),

              Text(
                l10n.appName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.loginTitle,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 40.h),

              CustomTextField(label: l10n.email, controller: emailController),
              SizedBox(height: 16.h),
              CustomTextField(
                label: l10n.password,
                controller: passwordController,
                isPassword: true,
              ),
              SizedBox(height: 32.h),

              PrimaryButton(
                text: l10n.signIn,
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
                      l10n.orSignInWith,
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              SizedBox(height: 24.h),

              SocialLoginButton(
                text: 'Google',
                imagePath: AppImages.appIcons.gmailLogo,
                onPressed: () {},
              ),

              SizedBox(height: 32.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${l10n.dontHaveAccount} ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(
                      l10n.signUp,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40.h),

              // KHU VỰC TEST NHANH SNACKBAR (Xóa đi khi release)
              Divider(color: Colors.grey.shade300),
              Text(
                'Test SnackBar Tool',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.check_circle, color: AppColors.success),
                    onPressed: () => TSnackBarHelper.showSuccess(
                      context,
                      message: 'Test thành công',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.error, color: AppColors.error),
                    onPressed: () => TSnackBarHelper.showError(
                      context,
                      message: 'Test lỗi hệ thống',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.warning, color: AppColors.warning),
                    onPressed: () => TSnackBarHelper.showWarning(
                      context,
                      message: 'Test cảnh báo rủi ro',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info, color: AppColors.info),
                    onPressed: () => TSnackBarHelper.showInfo(
                      context,
                      message: 'Test thông tin người dùng',
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
