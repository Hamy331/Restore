import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Mức độ sử dụng hạn mức: còn thoải mái, sắp hết, đã hết
enum AppQuotaLevel {
  normal,
  almostFull,
  full;

  static AppQuotaLevel of(int used, int limit) => used >= limit
      ? full
      : limit - used == 1
      ? almostFull
      : normal;

  Color get color => switch (this) {
    normal => AppColors.primaryDark,
    almostFull => AppColors.warning,
    full => AppColors.error,
  };

  Color get background => switch (this) {
    normal => AppColors.primarySoft,
    almostFull => AppColors.warningBg,
    full => AppColors.errorBg,
  };
}

/// Thanh chia ô thể hiện đã dùng bao nhiêu suất trên tổng [limit].
/// Giới hạn lớn (VD 30 tin) thì vẽ thành thanh liền thay vì từng ô.
class AppQuotaMeter extends StatelessWidget {
  final int used;
  final int limit;
  final double height;

  const AppQuotaMeter({
    super.key,
    required this.used,
    required this.limit,
    this.height = 6,
  });

  static const int _maxSegments = 10;

  @override
  Widget build(BuildContext context) {
    final level = AppQuotaLevel.of(used, limit);
    final empty = level.color.withValues(alpha: 0.14);
    final radius = BorderRadius.circular(height);

    if (limit > _maxSegments) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            duration: AppAnimationDurations.normal,
            curve: AppAnimationDurations.enterCurve,
            tween: Tween(end: (used / limit).clamp(0, 1).toDouble()),
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              color: level.color,
              backgroundColor: empty,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < limit; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: AppAnimationDurations.normal,
              curve: AppAnimationDurations.enterCurve,
              height: height,
              decoration: BoxDecoration(
                color: i < used ? level.color : empty,
                borderRadius: radius,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Nhãn nhỏ dạng viên thuốc cho hạn mức, màu đổi theo [AppQuotaLevel]
class AppQuotaBadge extends StatelessWidget {
  final String label;
  final AppQuotaLevel level;
  final IconData? icon;

  const AppQuotaBadge({
    super.key,
    required this.label,
    required this.level,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: level.color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: level.color,
            ),
          ),
        ],
      ),
    );
  }
}
