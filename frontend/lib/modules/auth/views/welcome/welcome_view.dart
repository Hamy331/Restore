import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'welcome_mobile_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) =>
      TResponsiveLayout(mobile: WelcomeMobileView());
}
