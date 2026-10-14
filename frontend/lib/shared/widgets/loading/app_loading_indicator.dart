import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Loading 3 chấm nhún lần lượt theo màu cam của app.
/// Dùng thay CircularProgressIndicator ở mọi chỗ cần chờ ngắn
/// (tải thêm, kéo để làm mới, nút đang gửi...).
class AppLoadingIndicator extends StatefulWidget {
  /// Đường kính mỗi chấm
  final double dotSize;
  final Color color;

  /// false thì đứng yên (VD đang kéo nhưng chưa đủ để làm mới)
  final bool animating;

  const AppLoadingIndicator({
    super.key,
    this.dotSize = 8,
    this.color = AppColors.primary,
    this.animating = true,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AppLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final shouldAnimate =
        widget.animating && !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.dotSize;
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.3),
                child: _dot(i, size),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index, double size) {
    // Mỗi chấm lệch pha 1/6 vòng, nhún lên rồi về trong nửa đầu chu kỳ
    final phase = (_controller.value - index / 6) % 1;
    final t = phase < 0.5
        ? Curves.easeInOut.transform(1 - (phase * 4 - 1).abs())
        : 0.0;
    return Transform.translate(
      offset: Offset(0, -size * 0.6 * t),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.45 + 0.55 * t),
        ),
      ),
    );
  }
}
