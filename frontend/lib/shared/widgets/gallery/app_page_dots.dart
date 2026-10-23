import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Chấm chỉ báo trang: chấm đang xem kéo dài thành viên thuốc.
/// Quá nhiều trang thì chỉ hiện một cửa sổ [maxDots] chấm quanh trang hiện tại.
class AppPageDots extends StatelessWidget {
  final int count;
  final int current;
  final int maxDots;
  final Color activeColor;
  final Color inactiveColor;

  const AppPageDots({
    super.key,
    required this.count,
    required this.current,
    this.maxDots = 7,
    this.activeColor = AppColors.primary,
    this.inactiveColor = Colors.white,
  });

  static const double _size = 6;
  static const double _activeWidth = 18;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final visible = count < maxDots ? count : maxDots;
    final start = (current - visible ~/ 2).clamp(0, count - visible);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(_size * 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = start; i < start + visible; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == current ? _activeWidth : _size,
                height: _size,
                decoration: BoxDecoration(
                  color: i == current
                      ? activeColor
                      : inactiveColor.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(_size),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
