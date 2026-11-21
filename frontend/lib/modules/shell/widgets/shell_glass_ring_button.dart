import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/app_image_icon.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nút tròn kính mờ có vòng viền xanh gradient, icon ở giữa.
/// Dùng chung cho nút Đăng tin giữa thanh điều hướng và bong bóng AI
/// để hai nút cùng một kiểu.
class ShellGlassRingButton extends StatefulWidget {
  final IconData icon;

  /// Icon 3D (AppImages.uiIcons) thay cho [icon] khi có
  final String? image;
  final String label;
  final double size;
  final VoidCallback? onTap;

  /// Làm mờ nội dung phía sau mặt nút. Tắt khi nút nằm trên một lớp kính
  /// đã blur sẵn (nút giữa thanh điều hướng) để khỏi blur hai lần.
  final bool blur;

  const ShellGlassRingButton({
    super.key,
    required this.icon,
    this.image,
    required this.label,
    required this.onTap,
    this.size = 58,
    this.blur = true,
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
                    Color(0xFF8AB9FF),
                    AppColors.actionPrimary,
                    AppColors.actionPrimaryDark,
                    AppColors.actionPrimary,
                    Color(0xFF8AB9FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.actionPrimary.withValues(
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
                  enabled: widget.blur,
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
                            AppColors.actionSoft.withValues(alpha: 0.80),
                          ],
                        ),
                      ),
                      child: InkWell(
                        onTap: widget.onTap,
                        customBorder: const CircleBorder(),
                        child: Center(
                          // Đổi icon (VD đổi gói) thì xoay và phóng nhẹ
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                RotationTransition(
                                  turns: Tween(
                                    begin: -0.25,
                                    end: 0.0,
                                  ).animate(animation),
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                            child: widget.image == null
                                ? Icon(
                                    widget.icon,
                                    key: ValueKey(widget.icon),
                                    size: size * 0.44,
                                    color: AppColors.actionPrimaryDark,
                                  )
                                : AppImageIcon(
                                    widget.image!,
                                    key: ValueKey(widget.image),
                                    size: size * 0.52,
                                    fallback: widget.icon,
                                    fallbackColor: AppColors.actionPrimaryDark,
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
      ),
    );
  }
}
