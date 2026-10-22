import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/app_size_reporter.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/shared/widgets/glass/app_glass_scroll_header.dart';

/// Khung chung các trang "Báo khi có hàng", cùng kiểu với các bước đăng tin:
/// nền kính mờ, [header] nổi phía trên và nội dung cuộn xuyên bên dưới.
/// Chưa cuộn thì header trong suốt, cuộn xuống thì chuyển dần sang kính mờ.
///
/// [bodyBuilder] nhận [topInset] là chiều cao header (đã gồm thanh trạng
/// thái) để nội dung chừa chỗ phía trên.
class WantedAlertGlassScaffold extends StatefulWidget {
  final Widget header;
  final Widget Function(BuildContext context, double topInset) bodyBuilder;
  final Widget? bottomNavigationBar;

  /// Chiều cao header ước lượng (chưa gồm thanh trạng thái), chỉ dùng cho
  /// khung hình đầu tiên trước khi đo được chiều cao thật
  final double estimatedHeaderHeight;

  const WantedAlertGlassScaffold({
    super.key,
    required this.header,
    required this.bodyBuilder,
    this.bottomNavigationBar,
    this.estimatedHeaderHeight = 64,
  });

  @override
  State<WantedAlertGlassScaffold> createState() =>
      _WantedAlertGlassScaffoldState();
}

class _WantedAlertGlassScaffoldState extends State<WantedAlertGlassScaffold> {
  /// Quãng cuộn (px) để lớp kính đầu trang hiện rõ hoàn toàn
  static const double _glassFadeDistance = 32;

  final _glassProgress = ValueNotifier<double>(0);
  double? _headerHeight;

  @override
  void dispose() {
    _glassProgress.dispose();
    super.dispose();
  }

  /// Theo dõi danh sách dọc chính (bỏ qua dải cuộn ngang bên trong), kể cả
  /// khi nội dung đổi sang danh sách khác
  bool _onScroll(ScrollMetrics metrics, int depth) {
    if (depth == 0 && metrics.axis == Axis.vertical) {
      _glassProgress.value = (metrics.pixels / _glassFadeDistance).clamp(
        0.0,
        1.0,
      );
    }
    return false;
  }

  void _onHeaderSize(Size size) {
    if (!mounted || size.height == _headerHeight) return;
    setState(() => _headerHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final topInset =
        _headerHeight ??
        MediaQuery.paddingOf(context).top + widget.estimatedHeaderHeight;

    return AppGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) => _onScroll(n.metrics, n.depth),
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (n) => _onScroll(n.metrics, n.depth),
            child: Stack(
              children: [
                Positioned.fill(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: Builder(
                      builder: (context) =>
                          widget.bodyBuilder(context, topInset),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppGlassScrollHeader(
                    progress: _glassProgress,
                    child: AppSizeReporter(
                      onSize: _onHeaderSize,
                      child: widget.header,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }
}
