import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Nền của các trang form (Xu, Gói tài khoản, Báo khi có hàng, Tin nháp,
/// Đăng tin...): trắng trơn, dùng chung cho điện thoại và web desktop để
/// hai bản cùng một hệ giao diện. Giữ tên cũ để các trang không phải sửa.
class AppGlassBackground extends StatelessWidget {
  final Widget child;

  const AppGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppColors.surface, child: child);
}
