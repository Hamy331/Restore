import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE9A529);
  static const Color primaryDark = Color(0xFFA65B00);

  /// Xám trung tính nhạt cho ô nhấn nhẹ (nhãn, ô chọn, thông báo nhỏ);
  /// không còn tông vàng kem để nền các trang và form luôn sạch
  static const Color primarySoft = Color(0xFFF4F5F7);

  /// Màu hành động (nút chính, mục điều hướng đang chọn): xanh theo logo
  static const Color actionPrimary = Color(0xFF1068FE);
  static const Color actionPrimaryDark = Color(0xFF0956D6);
  static const Color actionSoft = Color(0xFFEDF4FF);
  static const Color onAction = Colors.white;

  /// Nền trang và form: trắng
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// Nền ô nhập, skeleton, chip và khung chờ ảnh: xám trung tính nhạt,
  /// đủ tương phản trên nền trắng
  static const Color fill = Color(0xFFF4F5F7);
  static const Color cream = fill;
  static const Color textPrimary = Color(0xFF29231B);
  static const Color textSecondary = Color(0xFF70695F);
  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF006622);
  static const Color error = Color(0xFFB91C1C);
  static const Color warning = Color(0xFF92400E);
  static const Color info = Color(0xFF1D4ED8);

  static const Color successBg = Color(0xFFF0FDF4);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color infoBg = Color(0xFFEFF6FF);

  static const Color shadow = Color(0x0A000000);
}
