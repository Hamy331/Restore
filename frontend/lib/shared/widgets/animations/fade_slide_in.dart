import 'package:flutter/material.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Hiệu ứng xuất hiện: mờ dần + trượt lên nhẹ.
/// Truyền [index] để các phần tử trong danh sách xuất hiện lần lượt.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppAnimationDurations.slow,
    this.offsetY = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimationDurations.enterCurve,
    );
    final delay = AppAnimationDurations.staggerStep * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _animation.value)),
          child: child,
        ),
      ),
    );
  }
}
