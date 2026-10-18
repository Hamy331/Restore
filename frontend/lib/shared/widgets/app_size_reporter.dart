import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Báo kích thước [child] sau mỗi lần đổi (gọi sau khung hình), dùng khi
/// phần nội dung cần chừa chỗ cho một header nổi có chiều cao thay đổi.
class AppSizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;

  const AppSizeReporter({
    super.key,
    required this.onSize,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderAppSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAppSizeReporter renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

/// RenderObject của [AppSizeReporter]
class RenderAppSizeReporter extends RenderProxyBox {
  RenderAppSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _lastSize) return;
    _lastSize = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}
