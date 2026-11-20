import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dải trắng dưới đáy màn hình cho máy Android dùng thanh 3 nút (Back, Home,
/// Recent).
///
/// App vẽ tràn viền (edge-to-edge, bắt buộc từ Android 15), nên thanh 3 nút
/// trong suốt nằm đè lên nội dung cuối trang: nút Lưu, ô nhập ở cuối sheet...
/// Khi phát hiện thanh 3 nút, toàn app được thu gọn lên trên nó và phần
/// dưới tô trắng, icon nút màu tối. Máy dùng cử chỉ (chỉ có vạch mảnh) giữ
/// nguyên giao diện tràn viền để thanh điều hướng kính vẫn mờ tới đáy.
///
/// Dùng ở `MaterialApp.builder` để áp cho mọi trang, sheet và dialog.
class AppSystemNavBarGuard extends StatelessWidget {
  const AppSystemNavBarGuard({super.key, required this.child});

  final Widget child;

  /// Thanh 3 nút cao 48 dp; vạch cử chỉ chỉ khoảng 16 đến 34 dp
  static const double minButtonBarHeight = 40;

  static const Color barColor = Colors.white;

  /// Chiều cao thanh 3 nút cần chừa ra, 0 nếu máy không dùng thanh 3 nút
  static double buttonBarHeight(MediaQueryData media) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return 0;
    final bottom = media.viewPadding.bottom;
    return bottom >= minButtonBarHeight ? bottom : 0;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bar = buttonBarHeight(media);
    if (bar == 0) return child;

    // Phần app phía trên không còn bị thanh hệ thống che ở đáy; bàn phím
    // (viewInsets) tính từ đáy màn hình nên trừ đi phần đã chừa
    final inner = media.copyWith(
      padding: media.padding.copyWith(bottom: 0),
      viewPadding: media.viewPadding.copyWith(bottom: 0),
      viewInsets: media.viewInsets.copyWith(
        bottom: math.max(0, media.viewInsets.bottom - bar),
      ),
    );

    return Column(
      children: [
        Expanded(
          child: MediaQuery(data: inner, child: child),
        ),
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: barColor,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: SizedBox(
            key: const ValueKey('system-nav-bar-guard'),
            height: bar,
            width: double.infinity,
            child: const ColoredBox(color: barColor),
          ),
        ),
      ],
    );
  }
}
