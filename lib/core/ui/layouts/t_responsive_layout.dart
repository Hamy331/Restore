import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:restore/core/constants/app_dimesions.dart';

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
      final Widget desktopWidget =
          desktop ?? _buildDefaultPlaceholder("Desktop");
      final Widget tabletWidget = tablet ?? desktopWidget;

      if (width >= AppDimesions.desktopWidth) return desktopWidget;
      if (width >= AppDimesions.mobileWidth) return tabletWidget;
      return mobile;
    } else {
      if (width >= AppDimesions.mobileWidth) {
        return const Scaffold(
          body: Center(child: Text("App chỉ hỗ trợ trên thiết bị di động")),
        );
      }
      return mobile;
    }
  }

  Widget _buildDefaultPlaceholder(String platform) {
    return Scaffold(body: Center(child: Text("$platform Version Coming Soon")));
  }
}
