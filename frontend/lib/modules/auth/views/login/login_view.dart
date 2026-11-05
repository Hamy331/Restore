import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:flutter/material.dart';
import 'login_mobile_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TResponsiveLayout(mobile: LoginMobileView());
  }
}
