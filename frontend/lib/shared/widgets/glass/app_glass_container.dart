import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/theme/app_glass.dart';

/// Khối kính mờ: nền trong mờ + viền sáng + bóng mềm.
/// Bật [blur] khi khối nằm đè lên nội dung cuộn (thanh trên/dưới, sheet).
class AppGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool blur;
  final Color? color;
  final Color? borderColor;
  final bool showShadow;

  const AppGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = false,
    this.color,
    this.borderColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppGlass.radius);
    // Material (thay vì DecoratedBox) để hiệu ứng chạm của ListTile/InkWell
    // bên trong vẫn hiện trên nền kính
    Widget content = Material(
      color: color ?? AppGlass.fill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? AppGlass.stroke),
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (blur) {
      content = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow ? AppGlass.shadow : null,
      ),
      child: ClipRRect(borderRadius: radius, child: content),
    );
  }
}
