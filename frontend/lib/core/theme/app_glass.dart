import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Thông số giao diện kính mờ (glassmorphism) dùng chung.
/// Chỉ thanh trên/dưới và bottom sheet dùng blur thật để tránh giật,
/// còn thẻ nội dung dùng nền trong mờ đặt trên nền gradient.
class AppGlass {
  AppGlass._();

  static const double blurSigma = 18;
  static const double radius = 24;
  static const double fieldRadius = 18;

  static final Color fill = Colors.white.withValues(alpha: 0.62);
  static final Color fillStrong = Colors.white.withValues(alpha: 0.78);
  static final Color fillSoft = Colors.white.withValues(alpha: 0.45);
  static final Color stroke = Colors.white.withValues(alpha: 0.85);
  static final Color strokeSoft = AppColors.primary.withValues(alpha: 0.18);

  static final List<BoxShadow> shadow = [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Viền sáng phía trên giúp mặt kính có chiều sâu
  static LinearGradient sheen({double opacity = 1}) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.75 * opacity),
      Colors.white.withValues(alpha: 0.35 * opacity),
    ],
  );

  static const List<Color> backgroundGradient = [
    Color(0xFFFFF6E4),
    Color(0xFFFFFBF4),
    Color(0xFFFDEFE3),
  ];
}
