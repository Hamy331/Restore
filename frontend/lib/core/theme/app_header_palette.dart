import 'package:flutter/material.dart';

/// Màu vùng đầu trang (tiêu đề + ô tìm kiếm) ở trang chủ và các trang danh
/// sách như Gần bạn, dùng chung cho điện thoại và web desktop: xanh đậm trơn
/// theo màu logo Restore, chữ trắng. Phần nội dung trắng bo góc nằm ngay
/// bên dưới.
class AppHeaderPalette {
  AppHeaderPalette._();

  /// Xanh thân túi trong logo
  static const Color top = Color(0xFF213A9D);
  static const Color bottom = top;

  /// Chữ / icon đặt trực tiếp trên nền đầu trang
  static const Color foreground = Colors.white;
  static const Color foregroundMuted = Color(0xD9FFFFFF);

  /// Web desktop: thanh chính (logo, tìm kiếm, tài khoản)
  static const Color desktopBar = top;

  /// Web desktop: thanh liên kết nhanh (xanh logo sáng hơn một chút)
  static const Color desktopNav = Color(0xFF2A48AF);

  /// Giữ tên cũ cho các nơi đang dùng; hai đầu cùng màu nên là màu trơn
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
  );
}
