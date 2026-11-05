import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'email_verification_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import '../../bloc/otp/otp_cubit.dart';
import '../../bloc/verify_email/verify_email_cubit.dart';

class EmailVerificationView extends StatelessWidget {
  const EmailVerificationView({required this.email, super.key});
  final String email;

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => OtpCubit(authRepository)..startTimer()),
        BlocProvider(create: (_) => VerifyEmailCubit(authRepository)),
      ],
      child: TResponsiveLayout(
        mobile: EmailVerificationMobileView(email: email),
      ),
    );
  }
}
