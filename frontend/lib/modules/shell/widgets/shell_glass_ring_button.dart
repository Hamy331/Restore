import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nút tròn kính mờ có vòng viền cam gradient, icon ở giữa.
/// Dùng chung cho nút Đăng tin giữa thanh điều hướng và bong bóng AI
/// để hai nút cùng một kiểu.
class ShellGlassRingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final VoidCallback? onTap;

  const ShellGlassRingButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 58,
  });

  static const double _ringWidth = 2.5;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(_ringWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Color(0xFFFFD27A),
                AppColors.primary,
                Color(0xFFDC8A22),
                AppColors.primary,
                Color(0xFFFFD27A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 14,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Material(
                type: MaterialType.transparency,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.92),
                        AppColors.primarySoft.withValues(alpha: 0.80),
                      ],
                    ),
                  ),
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Icon(
                        icon,
                        size: size * 0.44,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
