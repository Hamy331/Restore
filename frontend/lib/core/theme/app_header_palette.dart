import 'package:flutter/material.dart';

/// Màu vùng đầu trang (tiêu đề + ô tìm kiếm) ở trang chủ và các trang danh
/// sách như Gần bạn: cam kem nhạt chuyển dần, đủ sáng để chữ tối nổi rõ.
/// Phần nội dung trắng bo góc nằm ngay bên dưới.
class AppHeaderPalette {
  AppHeaderPalette._();

  static const Color top = Color(0xFFFFF4E0);
  static const Color bottom = Color(0xFFFFE8C2);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
  );
}
