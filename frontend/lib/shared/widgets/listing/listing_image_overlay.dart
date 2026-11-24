import 'package:flutter/material.dart';

/// Chữ và icon trắng nổi trực tiếp trên ảnh, có bóng nhẹ để dễ đọc.
class ListingImageOverlay extends StatelessWidget {
  const ListingImageOverlay({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;

  static const shadows = [
    Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: IconTheme(
      data: const IconThemeData(color: Colors.white, shadows: shadows),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, shadows: shadows),
        child: child,
      ),
    ),
  );
}
