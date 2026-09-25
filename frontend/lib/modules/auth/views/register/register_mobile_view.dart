import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/shared/widgets/primary_button.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers/t_snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth_layout.dart';
import '../../bloc/register/register_bloc.dart';
import '../../bloc/register/register_event.dart';
import '../../bloc/register/register_state.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class RegisterMobileView extends StatelessWidget {
  const RegisterMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final fullNameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return AuthLayout(
      child: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterFailure) {
            TSnackBarHelper.showError(context, message: state.error);
          } else if (state is RegisterSuccess) {
            TSnackBarHelper.showSuccess(
              context,
              message: 'Registration successful! Please sign in.',
            );
            context.go('/login');
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.signUp,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Create a new account to experience the system',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 32.h),

              CustomTextField(
                label: 'Full Name',
                controller: fullNameController,
              ),
              SizedBox(height: 16.h),

              CustomTextField(
                label: 'Username',
                controller: usernameController,
              ),
              SizedBox(height: 16.h),

              CustomTextField(label: l10n.email, controller: emailController),
              SizedBox(height: 16.h),

              CustomTextField(
                label: l10n.password,
                controller: passwordController,
                isPassword: true,
              ),
              SizedBox(height: 32.h),

              PrimaryButton(
                text: l10n.signUp,
                isLoading: state is RegisterLoading,
                onPressed: () {
                  context.read<RegisterBloc>().add(
                    SubmitRegisterEvent(
                      fullName: fullNameController.text,
                      username: usernameController.text,
                      email: emailController.text,
                      password: passwordController.text,
                    ),
                  );
                },
              ),

              SizedBox(height: 24.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      l10n.signIn,
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
