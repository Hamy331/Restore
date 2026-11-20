import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'welcome_mobile_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Web desktop vào thẳng trang chủ như các sàn TMĐT; đăng nhập / đăng ký
    // nằm ở góc phải header
    if (isDesktopLayout(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const ColoredBox(color: Colors.white);
    }
    return TResponsiveLayout(mobile: WelcomeMobileView());
  }
}
