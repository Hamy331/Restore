import 'package:flutter/material.dart';
import '../../constants/app_dimesions.dart';

class TResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final bool isAlwaysAllowed;

  const TResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.isAlwaysAllowed = false,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    if (width >= AppDimesions.desktopWidth) {
      return desktop ?? tablet ?? mobile;
    }
    if (width >= AppDimesions.mobileWidth) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}
