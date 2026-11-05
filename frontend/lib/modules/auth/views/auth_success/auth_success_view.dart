import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'auth_success_mobile_view.dart';

class AuthSuccessView extends StatelessWidget {
  const AuthSuccessView({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.destination,
    this.note,
    this.authenticateOnContinue = false,
  });
  final String title;
  final String description;
  final String actionLabel;
  final String destination;
  final String? note;
  final bool authenticateOnContinue;
  @override
  Widget build(BuildContext context) => TResponsiveLayout(
    mobile: AuthSuccessMobileView(
      title: title,
      description: description,
      actionLabel: actionLabel,
      destination: destination,
      note: note,
      authenticateOnContinue: authenticateOnContinue,
    ),
  );
}
