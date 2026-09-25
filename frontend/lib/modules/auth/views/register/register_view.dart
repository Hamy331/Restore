import 'package:flutter/material.dart';
import 'package:restore/modules/auth/views/register/register_mobile_view.dart';
import '../../../../core/ui/layouts/t_responsive_layout.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TResponsiveLayout(mobile: RegisterMobileView()),
    );
  }
}
