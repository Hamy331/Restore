import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../repositories/auth_repository.dart';
import '../../bloc/otp/otp_cubit.dart';
import '../../bloc/otp/otp_state.dart';
import '../../bloc/verify_email/verify_email_cubit.dart';
import '../../bloc/verify_email/verify_email_state.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/otp_input.dart';

class EmailVerificationView extends StatelessWidget {
  const EmailVerificationView({required this.email, super.key});
  final String email;

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OtpCubit(authRepository)..startTimer(),
        ),
        BlocProvider(
          create: (_) => VerifyEmailCubit(authRepository),
        ),
      ],
      child: _EmailVerificationViewBody(email: email),
    );
  }
}

class _EmailVerificationViewBody extends StatefulWidget {
  const _EmailVerificationViewBody({required this.email});
  final String email;

  @override
  State<_EmailVerificationViewBody> createState() =>
      _EmailVerificationViewBodyState();
}

class _EmailVerificationViewBodyState
    extends State<_EmailVerificationViewBody> {
  String _otp = '';
  String? _localError;

  @override
  Widget build(BuildContext context) {
    final email = widget.email.isEmpty ? 'phat.ngo@email.com' : widget.email;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
      listener: (context, verifyState) {
        if (verifyState is VerifyEmailSuccess) {
          context.go('/email-verified');
        }
      },
      builder: (context, verifyState) {
        return AuthScreen(
          title: l10n.verifyEmailTitle,
          onBack: () => context.go('/register'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthContextIcon(Icons.mark_email_unread_outlined),
              const SizedBox(height: 13),
              Text(
                l10n.enterVerificationCode,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                l10n.otpSentToEmail(email),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 13),
              OtpInput(onChanged: (value) => _otp = value),
              const SizedBox(height: 13),
              BlocBuilder<OtpCubit, OtpState>(
                builder: (context, state) {
                  return Center(
                    child: Text(
                      l10n.otpValidFor(state.formattedTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: state.isExpired
                            ? Colors.red
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
              if (_localError != null) ...[
                const SizedBox(height: 13),
                AuthFeedback(message: _localError!),
              ] else if (verifyState is VerifyEmailFailure) ...[
                const SizedBox(height: 13),
                AuthFeedback(message: verifyState.error),
              ],
              const SizedBox(height: 13),
              BlocBuilder<OtpCubit, OtpState>(
                builder: (context, otpState) {
                  return AppButton(
                    label: verifyState is VerifyEmailLoading
                        ? 'Đang xử lý...'
                        : l10n.verifyEmailButton,
                    isLoading: verifyState is VerifyEmailLoading,
                    onPressed: otpState.isExpired ? null : () => _verify(l10n),
                  );
                },
              ),
              const SizedBox(height: 13),
              BlocBuilder<OtpCubit, OtpState>(
                builder: (context, state) {
                  return Center(
                    child: TextButton(
                      onPressed: state.isExpired
                          ? () async {
                              try {
                                await context.read<OtpCubit>().resendOtp(email);
                              } catch (_) {}
                            }
                          : null,
                      child: Text(
                        l10n.resendOtp,
                        style: TextStyle(
                          fontSize: 12,
                          color: state.isExpired
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 13),
              AuthInfoBox(message: l10n.emailVerifyInfo),
            ],
          ),
        );
      },
    );
  }

  void _verify(AppLocalizations l10n) {
    if (_otp.length != 6) {
      setState(() => _localError = l10n.invalidOtpError);
      return;
    }
    setState(() => _localError = null);
    context.read<VerifyEmailCubit>().verifyOtp(widget.email, _otp);
  }
}
