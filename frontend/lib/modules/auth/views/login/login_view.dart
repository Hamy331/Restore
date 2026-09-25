import 'package:flutter/material.dart';
import '../../../../core/ui/layouts/t_responsive_layout.dart';
import 'login_mobile_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: TResponsiveLayout(mobile: LoginMobileView()));
  }
}
