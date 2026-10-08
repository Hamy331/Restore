import 'package:flutter/material.dart';

class BounceAnimationWrapper extends StatelessWidget {
  final Widget child;
  final int index;
  final AnimationController controller;

  const BounceAnimationWrapper({
    super.key,
    required this.child,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.1;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: Curves.elasticOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, childWidget) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
