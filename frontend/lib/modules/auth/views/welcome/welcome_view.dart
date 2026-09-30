import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFFCF7);
    final tablet = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: tablet ? AppColors.background : backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => Center(
            child: Container(
              width: tablet ? 520 : viewport.maxWidth,
              height: tablet
                  ? (viewport.maxHeight - 56).clamp(0, 812).toDouble()
                  : viewport.maxHeight,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: tablet ? Border.all(color: AppColors.border) : null,
                borderRadius: tablet ? BorderRadius.circular(16) : null,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? 24 : 20,
                vertical: 16,
              ),
              child: LayoutBuilder(
                builder: (context, space) {
                  final compact = space.maxHeight < 700;
                  final gap = compact ? 8.0 : 14.0;
                  final buttonHeight = compact ? 48.0 : 52.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.autorenew, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'ReStore',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, heroSpace) {
                            final heroWidth = space.maxWidth
                                .clamp(0, 420)
                                .toDouble();
                            return Center(
                              child: SizedBox(
                                width: heroWidth,
                                height: heroSpace.maxHeight
                                    .clamp(0, heroWidth / .9)
                                    .toDouble(),
                                child: const _MarketplaceHero(),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: gap),
                      Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'Đồ tốt\n'),
                            TextSpan(
                              text: 'tìm chủ mới.',
                              style: TextStyle(color: Color(0xFFC87800)),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: compact ? 30 : 36,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      Text(
                        'Mua bán đồ đã qua sử dụng quanh bạn. Nhắn tin và thương lượng trực tiếp với người bán.',
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          height: compact ? 1.35 : 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: gap),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: compact ? 44 : 52,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: compact ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 19,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Một tài khoản để vừa mua vừa bán.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: gap),
                      AppButton(
                        label: 'Đăng nhập',
                        height: buttonHeight,
                        borderRadius: 28,
                        onPressed: () => context.go('/login'),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      AppButton(
                        label: 'Đăng ký',
                        variant: AppButtonVariant.secondary,
                        height: buttonHeight,
                        borderRadius: 28,
                        onPressed: () => context.go('/register'),
                      ),
                      SizedBox(height: compact ? 0 : 4),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/home'),
                          child: const Text(
                            'Tiếp tục xem tin không cần tài khoản ›',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth/welcome-collage.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: width * .06,
            bottom: 42,
            child: _HeroLabel(
              category: 'ĐIỆN THOẠI & ĐIỆN TỬ',
              title: 'Laptop',
              width: width * .46,
            ),
          ),
          Positioned(
            right: width * .03,
            bottom: 18,
            child: _HeroLabel(
              category: 'NỘI THẤT',
              title: 'Ghế gỗ',
              width: width * .35,
            ),
          ),
          Positioned(
            left: width * .11,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    '1,2 km · Đang thương lượng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _HeroLabel extends StatelessWidget {
  const _HeroLabel({
    required this.category,
    required this.title,
    required this.width,
  });

  final String category;
  final String title;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}
