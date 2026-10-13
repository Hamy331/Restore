import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Mở bottom sheet kính mờ dạng "thẻ nổi":
/// - Trang phía sau mờ dần theo animation mở sheet.
/// - Sheet tách khỏi mép màn hình, bo tròn cả 4 góc, có ánh màu ấm loang
///   và viền sáng như mặt kính.
/// - Đầu sheet có thanh kéo, icon minh hoạ [icon] (tuỳ chọn), tiêu đề,
///   [subtitle] và nút đóng.
///
/// [heightFactor] null thì sheet cao theo nội dung (tối đa 85% màn hình).
Future<T?> showAppGlassSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  String? subtitle,
  IconData? icon,
  double? heightFactor,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _GlassSheetRoute<T>(
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (sheetContext) => _AppGlassSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        heightFactor: heightFactor,
        builder: builder,
      ),
    ),
  );
}

/// Route bottom sheet có lớp nền phía sau được làm mờ dần (blur + phủ màu)
class _GlassSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _GlassSheetRoute({
    required super.builder,
    super.capturedThemes,
    super.barrierLabel,
  }) : super(
         isScrollControlled: true,
         backgroundColor: Colors.transparent,
         elevation: 0,
         modalBarrierColor: AppColors.textPrimary.withValues(alpha: 0.18),
       );

  static const double _maxBarrierBlur = 6;

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    return AnimatedBuilder(
      animation: animation!,
      child: barrier,
      builder: (context, child) {
        final t = Curves.easeOut.transform(animation!.value);
        if (t == 0) return child!;
        final sigma = _maxBarrierBlur * t;
        // Phủ trắng nhẹ dần về phía đáy để màu nút cam phía sau không loang
        // thành một mảng dưới mép sheet
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1],
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.7 * t),
                ],
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _AppGlassSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final double? heightFactor;
  final WidgetBuilder builder;

  const _AppGlassSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.heightFactor,
    required this.builder,
  });

  static const double _margin = 8;
  static const double _radius = 32;
  static const double _blur = 28;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight =
        media.size.height * (heightFactor ?? 0.85) - media.padding.top;
    final radius = BorderRadius.circular(_radius);

    return Padding(
      // Sheet nổi cách mép, đẩy lên khi bàn phím mở (ô tìm kiếm, địa chỉ)
      padding: EdgeInsets.fromLTRB(
        _margin,
        0,
        _margin,
        _margin +
            (media.viewInsets.bottom > 0
                ? media.viewInsets.bottom
                : media.padding.bottom),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          // Bóng trung tính, mảnh: chỉ tách sheet khỏi nền, không loang màu
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
            child: CustomPaint(
              painter: _SheetGlassPainter(radius: _radius),
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  height: heightFactor == null ? null : maxHeight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _DragHandle(),
                          _SheetHeader(
                            title: title,
                            subtitle: subtitle,
                            icon: icon,
                          ),
                          Flexible(
                            fit: heightFactor == null
                                ? FlexFit.loose
                                : FlexFit.tight,
                            child: Builder(builder: builder),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vẽ mặt kính của sheet: nền trắng trong mờ, hai đốm màu ấm loang ở góc
/// và viền sáng mảnh (đậm ở trên, nhạt dần xuống dưới).
class _SheetGlassPainter extends CustomPainter {
  final double radius;
  const _SheetGlassPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.88),
            Colors.white.withValues(alpha: 0.84),
          ],
        ).createShader(rect),
    );

    void glow(Offset center, double r, Color color) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    canvas.save();
    canvas.clipRRect(rrect);
    glow(
      Offset(size.width * 0.12, 0),
      size.width * 0.55,
      AppColors.primary.withValues(alpha: 0.20),
    );
    glow(
      Offset(size.width * 0.95, size.height * 0.35),
      size.width * 0.45,
      const Color(0xFFFF9F7A).withValues(alpha: 0.12),
    );
    canvas.restore();

    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white.withValues(alpha: 0.6)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SheetGlassPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const _SheetHeader({required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            AppGlassIconBadge(icon: icon!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GlassCloseButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
    );
  }
}

/// Huy hiệu icon tròn: nền gradient ấm, viền sáng, icon ở giữa.
/// Dùng ở đầu sheet và cho các lựa chọn dạng thẻ.
class AppGlassIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  const AppGlassIconBadge({super.key, required this.icon, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4DC), Color(0xFFFFDDA6)],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: size * 0.5, color: AppColors.primaryDark),
      ),
    );
  }
}

class _GlassCloseButton extends StatelessWidget {
  final String tooltip;
  const _GlassCloseButton({required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          shape: CircleBorder(
            side: BorderSide(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox.square(
              dimension: 38,
              child: Icon(
                AppIcons.closeStrong,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
