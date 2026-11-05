import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'splash_mobile_view.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) =>
      TResponsiveLayout(mobile: SplashMobileView());
}
