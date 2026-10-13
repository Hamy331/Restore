import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import 'shell_glass_ring_button.dart';

/// Bong bóng chat AI nổi trên các tab chính, nhấn vào để mở ReStore AI.
///
/// Kéo được và tự hít vào mép trái/phải gần nhất khi thả, luôn nằm phía
/// trên thanh điều hướng (dựa vào MediaQuery padding dưới của body).
/// Đặt widget này trong Stack phủ kín vùng nội dung.
class ShellAiBubble extends StatefulWidget {
  final VoidCallback onTap;

  const ShellAiBubble({super.key, required this.onTap});

  @override
  State<ShellAiBubble> createState() => _ShellAiBubbleState();
}

class _ShellAiBubbleState extends State<ShellAiBubble>
    with SingleTickerProviderStateMixin {
  static const double _size = 54;
  static const double _edge = 14;

  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool _onRight = true;

  /// Khoảng cách từ vị trí thấp nhất cho phép lên tới đáy bong bóng
  double _lift = 0;

  /// Toạ độ góc trên trái trong lúc đang kéo
  Offset? _dragPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tôn trọng cài đặt giảm chuyển động của hệ thống
    if (MediaQuery.disableAnimationsOf(context)) {
      _halo.stop();
    } else if (!_halo.isAnimating) {
      _halo.repeat();
    }
  }

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final minBottom = padding.bottom + 14;
        final maxLift = (height - padding.top - 96 - _size - minBottom).clamp(
          0.0,
          double.infinity,
        );
        final restingLeft = _onRight ? width - _size - _edge : _edge;
        final restingTop = height - minBottom - _lift.clamp(0, maxLift) - _size;
        final position = _dragPosition ?? Offset(restingLeft, restingTop);

        return Stack(
          children: [
            AnimatedPositioned(
              duration: _dragPosition == null
                  ? const Duration(milliseconds: 380)
                  : Duration.zero,
              curve: Curves.easeOutBack,
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                onPanStart: (_) => setState(() => _dragPosition = position),
                onPanUpdate: (details) => setState(() {
                  final next = _dragPosition! + details.delta;
                  _dragPosition = Offset(
                    next.dx.clamp(0, width - _size),
                    next.dy.clamp(padding.top, height - minBottom - _size),
                  );
                }),
                onPanEnd: (_) => setState(() {
                  final dropped = _dragPosition!;
                  _onRight = dropped.dx + _size / 2 > width / 2;
                  _lift = (height - minBottom - _size - dropped.dy).clamp(
                    0,
                    maxLift,
                  );
                  _dragPosition = null;
                }),
                child: AnimatedScale(
                  scale: _dragPosition == null ? 1 : 1.08,
                  duration: const Duration(milliseconds: 160),
                  child: _BubbleFace(
                    halo: _halo,
                    size: _size,
                    label: l10n.aiBubbleTooltip,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Mặt bong bóng: cùng kiểu nút tròn kính viền cam với nút Đăng tin,
/// thêm một vòng sáng lan ra nhịp nhàng để gợi ý có thể nhấn.
class _BubbleFace extends StatelessWidget {
  final Animation<double> halo;
  final double size;
  final String label;

  const _BubbleFace({
    required this.halo,
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: halo,
            builder: (context, _) {
              final t = Curves.easeOut.transform(halo.value);
              return Transform.scale(
                scale: 1 + 0.35 * t,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: 0.45 * (1 - t),
                      ),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          // Nhấn do GestureDetector bên ngoài xử lý (để còn kéo được)
          ShellGlassRingButton(
            icon: AppIcons.sparkleActive,
            label: label,
            size: size,
            onTap: null,
          ),
        ],
      ),
    );
  }
}
