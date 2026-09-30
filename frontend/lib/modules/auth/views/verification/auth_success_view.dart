import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../widgets/auth_screen.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthSuccessView extends StatelessWidget {
  const AuthSuccessView({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.destination,
    this.note,
    this.authenticateOnContinue = false,
    super.key,
  });

  final String title;
  final String description;
  final String actionLabel;
  final String destination;
  final String? note;
  final bool authenticateOnContinue;

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      centerContent: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 42,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 13),
          AppButton(
            label: actionLabel,
            onPressed: () {
              if (authenticateOnContinue) {
                context.read<AuthBloc>().add(const LoggedIn(role: 'USER'));
              } else {
                context.go(destination);
              }
            },
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                note!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
