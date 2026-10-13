import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';

/// Thanh nút kính mờ cố định ở cuối màn hình:
/// 1 nút chính và (tuỳ chọn) 1 nút phụ bên trái
class AppBottomActionBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  const AppBottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  static const double buttonHeight = 52;
  static final BorderRadius _radius = BorderRadius.circular(16);
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppGlass.fill,
            border: Border(top: BorderSide(color: AppGlass.stroke)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (secondaryLabel != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onSecondary,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppGlass.fillStrong,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(buttonHeight),
                          side: BorderSide(color: AppGlass.stroke),
                          shape: RoundedRectangleBorder(borderRadius: _radius),
                        ),
                        child: Text(secondaryLabel!, style: _labelStyle),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _PrimaryButton(
                      label: primaryLabel,
                      onPressed: isLoading ? null : onPrimary,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppBottomActionBar._radius;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFF2B54A)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
          minimumSize: const Size.fromHeight(AppBottomActionBar.buttonHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            : Text(label, style: AppBottomActionBar._labelStyle),
      ),
    );
  }
}
