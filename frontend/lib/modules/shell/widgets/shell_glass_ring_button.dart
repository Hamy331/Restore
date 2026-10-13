import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nút tròn kính mờ có vòng viền cam gradient, icon ở giữa.
/// Dùng chung cho nút Đăng tin giữa thanh điều hướng và bong bóng AI
/// để hai nút cùng một kiểu.
class ShellGlassRingButton extends StatefulWidget {
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

  @override
  State<ShellGlassRingButton> createState() => _ShellGlassRingButtonState();
}

/// Nhấn hoặc giữ thì nút lún xuống và vòng sáng đậm lên, thả tay thì nảy về.
/// Dùng Listener để vẫn có hiệu ứng khi cử chỉ do widget bên ngoài xử lý
/// (bong bóng AI kéo được).
class _ShellGlassRingButtonState extends State<ShellGlassRingButton> {
  static const double _ringWidth = 2.5;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Tooltip(
      message: widget.label,
      child: Semantics(
        button: true,
        label: widget.label,
        excludeSemantics: true,
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: _pressed
                ? const Duration(milliseconds: 110)
                : const Duration(milliseconds: 380),
            curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
                    color: AppColors.primary.withValues(
                      alpha: _pressed ? 0.55 : 0.30,
                    ),
                    blurRadius: _pressed ? 20 : 14,
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
                        onTap: widget.onTap,
                        customBorder: const CircleBorder(),
                        child: Center(
                          child: Icon(
                            widget.icon,
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
        ),
      ),
    );
  }
}
