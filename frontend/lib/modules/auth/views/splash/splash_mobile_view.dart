import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Hiện trong lúc khôi phục phiên đã lưu, thay vì để trang Welcome chớp qua
class SplashMobileView extends StatelessWidget {
  const SplashMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logos/app-logo.png', width: 96, height: 96),
            const SizedBox(height: 24),
            const AppLoadingIndicator(color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}
