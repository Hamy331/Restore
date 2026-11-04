import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Vòng tròn chọn ảnh đặt ở góc ô ảnh: chưa chọn là vòng trắng rỗng,
/// đã chọn là hình tròn màu ấm có số thứ tự (ảnh số 1 là ảnh bìa).
class AppSelectionBadge extends StatelessWidget {
  /// Thứ tự đã chọn, bắt đầu từ 1; null là chưa chọn
  final int? order;
  final double size;

  const AppSelectionBadge({super.key, this.order, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final selected = order != null;
    return AnimatedContainer(
      duration: AppAnimationDurations.normal,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? null : Colors.black.withValues(alpha: 0.15),
        gradient: selected
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFFF08A3C)],
              )
            : null,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6),
        ],
      ),
      child: selected
          ? Text(
              '$order',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.48,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
