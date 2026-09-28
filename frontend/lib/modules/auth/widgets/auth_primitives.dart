import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthContextIcon extends StatelessWidget {
  const AuthContextIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 25, color: AppColors.primaryDark),
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider()),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          'hoặc',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
      Expanded(child: Divider()),
    ],
  );
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(width: 9),
          Text(
            'Tiếp tục với Google',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

class AuthInfoBox extends StatelessWidget {
  const AuthInfoBox({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 59),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 19, color: AppColors.primaryDark),
        const SizedBox(width: 9),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class AuthFeedback extends StatelessWidget {
  const AuthFeedback({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 58),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.errorBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 19, color: AppColors.error),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    ),
  );
}

class ProtectedActionPrompt extends StatelessWidget {
  const ProtectedActionPrompt({
    required this.onLogin,
    required this.onContinueBrowsing,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onContinueBrowsing;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đăng nhập để tiếp tục',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Bạn có thể xem và tìm tin không cần tài khoản. Đăng nhập để lưu tin, nhắn người bán, trả giá hoặc đăng tin.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onLogin,
            child: const Text('Đăng nhập'),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: onContinueBrowsing,
            child: const Text(
              'Tiếp tục xem tin',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}
