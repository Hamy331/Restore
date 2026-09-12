import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:restore/core/constants/app_dimesions.dart';
import 't_size_error_layout.dart';

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

    if (kIsWeb || isAlwaysAllowed) {
      final Widget desktopWidget = desktop ?? const TSizeErrorLayout();
      final Widget tabletWidget = tablet ?? desktopWidget;

      if (width >= AppDimesions.desktopWidth) return desktopWidget;
      if (width >= AppDimesions.mobileWidth) return tabletWidget;
      return mobile;
    } else {
      if (width >= AppDimesions.mobileWidth) {
        return const TSizeErrorLayout();
      }
      return mobile;
    }
  }
}
