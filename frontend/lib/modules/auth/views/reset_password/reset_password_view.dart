import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'reset_password_mobile_view.dart';

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key, required this.resetToken});
  final String resetToken;
  @override
  Widget build(BuildContext context) => TResponsiveLayout(
    mobile: ResetPasswordMobileView(resetToken: resetToken),
  );
}
