// lib/shared/widgets/primary_button.dart
import 'package:flutter/material.dart';
import 'app_button.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(label: text, onPressed: onPressed, isLoading: isLoading);
  }
}
