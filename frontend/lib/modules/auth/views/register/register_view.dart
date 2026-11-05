import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:flutter/material.dart';
import 'register_mobile_view.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TResponsiveLayout(mobile: RegisterMobileView());
  }
}
