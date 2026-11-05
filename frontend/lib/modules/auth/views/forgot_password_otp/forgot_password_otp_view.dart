import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'forgot_password_otp_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/otp/otp_cubit.dart';

class ForgotPasswordOtpView extends StatelessWidget {
  const ForgotPasswordOtpView({required this.email, super.key});
  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpCubit()..startTimer(),
      child: TResponsiveLayout(
        mobile: ForgotPasswordOtpMobileView(email: email),
      ),
    );
  }
}
