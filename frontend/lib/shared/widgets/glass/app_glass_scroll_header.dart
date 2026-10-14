import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/theme/app_glass.dart';

/// Lớp phủ đầu trang dạng kính: lúc nội dung chưa cuộn thì trong suốt hoàn
/// toàn; càng cuộn ([progress] 0 → 1) càng mờ (blur), phủ trắng nhẹ, hiện
/// và viền sáng ở cạnh dưới. Nội dung vẫn nhìn thấy mờ mờ phía sau.
class AppGlassScrollHeader extends StatelessWidget {
  final ValueListenable<double> progress;
  final Widget child;

  const AppGlassScrollHeader({
    super.key,
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      child: child,
      builder: (context, t, child) {
        final decorated = DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42 * t),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.9 * t),
              ),
            ),
          ),
          child: child,
        );
        // Luôn giữ cùng cấu trúc cây (chỉ bật/tắt blur) để widget con
        // không bị dựng lại và chạy lại animation
        final sigma = AppGlass.blurSigma * t;
        return ClipRect(
          // Chưa cuộn thì không cắt, để bóng của thẻ bên trong hiện đủ
          clipBehavior: t > 0 ? Clip.hardEdge : Clip.none,
          child: BackdropFilter(
            enabled: t > 0,
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: decorated,
          ),
        );
      },
    );
  }
}
