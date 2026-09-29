import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          validator:
              widget.validator ??
              (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập ${widget.label.toLowerCase()}.'
                  : null,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            constraints: const BoxConstraints(minHeight: 49),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
