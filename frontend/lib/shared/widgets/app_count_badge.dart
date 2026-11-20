import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Chấm đỏ đếm số (thông báo chưa đọc, tin nhắn mới...) đặt ở góc [child].
/// [count] <= 0 thì chỉ hiện [child]; lớn hơn [max] hiện "9+".
class AppCountBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final int max;

  /// Lệch so với góc trên bên phải của [child]
  final Offset offset;

  const AppCountBadge({
    super.key,
    required this.count,
    required this.child,
    this.max = 9,
    this.offset = const Offset(2, -2),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: offset.dy,
          right: -offset.dx,
          child: IgnorePointer(
            child: AnimatedScale(
              scale: count > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Text(
                  count > max ? '$max+' : '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
