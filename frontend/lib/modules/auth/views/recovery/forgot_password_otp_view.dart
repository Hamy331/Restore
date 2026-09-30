import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../bloc/otp/otp_cubit.dart';
import '../../bloc/otp/otp_state.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_screen.dart';
import '../../widgets/otp_input.dart';

class ForgotPasswordOtpView extends StatelessWidget {
  const ForgotPasswordOtpView({required this.email, super.key});
  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpCubit()..startTimer(),
      child: _ForgotPasswordOtpViewBody(email: email),
    );
  }
}

class _ForgotPasswordOtpViewBody extends StatefulWidget {
  const _ForgotPasswordOtpViewBody({required this.email});
  final String email;

  @override
  State<_ForgotPasswordOtpViewBody> createState() =>
      _ForgotPasswordOtpViewBodyState();
}

class _ForgotPasswordOtpViewBodyState
    extends State<_ForgotPasswordOtpViewBody> {
  String _otp = '';
  String? _error;
  bool _isLoading = false;
  final _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    final email = widget.email.isEmpty ? '' : widget.email;
    final l10n = AppLocalizations.of(context)!;

    return AuthScreen(
      title: l10n.verifyOtpTitle,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthContextIcon(Icons.mail_lock_outlined),
          const SizedBox(height: 13),
          Text(
            l10n.checkYourEmail,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
          if (_error != null) ...[
            const SizedBox(height: 13),
            AuthFeedback(message: _error!),
          ],
          const SizedBox(height: 13),
          AppButton(
            label: _isLoading ? 'Đang xác thực...' : l10n.verifyOtpButton,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : () => _verify(l10n),
          ),
          const SizedBox(height: 13),
          BlocBuilder<OtpCubit, OtpState>(
            builder: (context, state) {
              return Center(
                child: TextButton(
                  onPressed: state.isExpired ? () => _resendOtp() : null,
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
          AuthInfoBox(message: l10n.otpExpireInfo),
        ],
      ),
    );
  }

  Future<void> _verify(AppLocalizations l10n) async {
    if (_otp.length != 6) {
      setState(() => _error = l10n.invalidOtpError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resetToken = await _authRepository.verifyForgotPasswordOtp(
        widget.email,
        _otp,
      );
      if (mounted) {
        context.push('/reset-password', extra: resetToken);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await _authRepository.forgotPassword(widget.email);
      if (mounted) {
        context.read<OtpCubit>().resetTimer();
        setState(() => _error = null);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }
}
