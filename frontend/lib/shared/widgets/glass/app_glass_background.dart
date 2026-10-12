import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';

/// Nền gradient ấm với vài đốm màu loang để lớp kính phía trên có chiều sâu.
/// Nền tĩnh, vẽ một lần nên không ảnh hưởng hiệu năng khi cuộn.
class AppGlassBackground extends StatelessWidget {
  final Widget child;

  const AppGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppGlass.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          const RepaintBoundary(
            child: Stack(
              children: [
                _Blob(
                  alignment: Alignment(-1.3, -0.9),
                  size: 280,
                  color: AppColors.primary,
                  opacity: 0.28,
                ),
                _Blob(
                  alignment: Alignment(1.4, -0.2),
                  size: 240,
                  color: Color(0xFFFF9F7A),
                  opacity: 0.18,
                ),
                _Blob(
                  alignment: Alignment(-0.8, 1.2),
                  size: 300,
                  color: Color(0xFFFFD27A),
                  opacity: 0.22,
                ),
              ],
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;
  final double opacity;

  const _Blob({
    required this.alignment,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
