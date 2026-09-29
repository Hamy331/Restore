import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../widgets/auth_screen.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      bottom: _WelcomeActions(
        onLogin: () => context.go('/login'),
        onRegister: () => context.go('/register'),
        onGuest: () => context.go('/home'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 76),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.autorenew,
                  size: 29,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 11),
              const Text(
                'ReStore',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'Đồ tốt tìm chủ mới',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mua bán đồ đã qua sử dụng quanh bạn. Nhắn tin và thương lượng trực tiếp với người bán.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 13),
          const SizedBox(
            height: 145,
            child: Row(
              children: [
                Expanded(
                  child: _PreviewCard(
                    asset: 'assets/images/auth/welcome-camera.png',
                    title: 'Canon AE-1',
                    price: '2.450.000 đ',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _PreviewCard(
                    asset: 'assets/images/auth/welcome-lamp.png',
                    title: 'Đèn bàn vintage',
                    price: '590.000 đ',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            height: 53,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.swap_horiz, size: 22, color: AppColors.primaryDark),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Một tài khoản để vừa mua vừa bán.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.asset,
    required this.title,
    required this.price,
  });

  final String asset;
  final String title;
  final String price;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 95,
            width: double.infinity,
            child: Image.asset(asset, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 4, 7, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    required this.onLogin,
    required this.onRegister,
    required this.onGuest,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
    child: Column(
      children: [
        AppButton(label: 'Đăng nhập', onPressed: onLogin),
        const SizedBox(height: 10),
        AppButton(
          label: 'Đăng ký',
          variant: AppButtonVariant.secondary,
          onPressed: onRegister,
        ),
        TextButton(
          onPressed: onGuest,
          child: const Text(
            'Tiếp tục xem tin không cần tài khoản  ›',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
