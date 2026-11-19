import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'image_crop.dart';

/// Vùng cắt: ảnh có thể kéo / thu phóng dưới một khung cố định ([CropFrame]).
/// Phần ảnh ngoài khung bị làm tối; trong khung, chỗ ảnh không phủ tới là nền
/// mờ của chính ảnh (giống ảnh sẽ xuất ra).
class ImageCropArea extends StatefulWidget {
  const ImageCropArea({
    super.key,
    required this.image,
    required this.frame,
    required this.transform,
    required this.onChanged,
    this.background,
  });

  /// Màu nền phần trống; `null` = nền mờ của chính ảnh
  final Color? background;

  final ui.Image image;
  final CropFrame frame;
  final ImageCropTransform transform;
  final ValueChanged<ImageCropTransform> onChanged;

  @override
  State<ImageCropArea> createState() => _ImageCropAreaState();
}

class _ImageCropAreaState extends State<ImageCropArea> {
  ImageCropTransform? _start;
  Offset _startFocal = Offset.zero;

  Size get _imageSize =>
      Size(widget.image.width.toDouble(), widget.image.height.toDouble());

  /// Phóng to / thu nhỏ quanh [focal] (toạ độ trong khung, px)
  ImageCropTransform _zoom(
    ImageCropTransform from,
    double factor,
    Offset focal,
    Offset moved,
    double unit,
    Size frame,
  ) {
    final newScale = (from.scale * factor)
        .clamp(
          ImageCropTransform.minScale(_imageSize, widget.frame),
          ImageCropTransform.maxScale(_imageSize, widget.frame),
        )
        .toDouble();
    final ratio = newScale / from.scale;
    final frameCenter = Offset(frame.width / 2, frame.height / 2);
    final centerPx = frameCenter + from.center * unit;
    final next = focal + moved + (centerPx - focal) * ratio;
    return ImageCropTransform(
      scale: newScale,
      center: (next - frameCenter) / unit,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // khung rộng hết chiều ngang (trừ lề), khung vuông thì không cao quá vùng
      final aspect = widget.frame.aspect;
      final width = math.min(
        constraints.maxWidth - 32,
        (constraints.maxHeight - 32) / aspect,
      );
      final frame = Size(width, width * aspect);
      final frameRect = Rect.fromCenter(
        center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
        width: frame.width,
        height: frame.height,
      );
      final transform = widget.transform;
      final imageRect = transform
          .imageRect(_imageSize, frame)
          .shift(frameRect.topLeft);
      final coverRect = ImageCropTransform.cover(
        _imageSize,
        widget.frame,
      ).imageRect(_imageSize, frame).shift(frameRect.topLeft);

      return Listener(
        // cuộn chuột để thu phóng (web / máy tính)
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent) return;
          final factor = event.scrollDelta.dy > 0 ? 1 / 1.1 : 1.1;
          widget.onChanged(
            _zoom(
              transform,
              factor,
              event.localPosition - frameRect.topLeft,
              Offset.zero,
              frame.width,
              frame,
            ),
          );
        },
        child: GestureDetector(
          key: const ValueKey('image-crop-area'),
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            _start = transform;
            _startFocal = details.localFocalPoint - frameRect.topLeft;
          },
          onScaleUpdate: (details) {
            final start = _start;
            if (start == null) return;
            final focal = details.localFocalPoint - frameRect.topLeft;
            widget.onChanged(
              _zoom(
                start,
                details.scale,
                _startFocal,
                focal - _startFocal,
                frame.width,
                frame,
              ),
            );
          },
          child: Stack(
            children: [
              // nền trong khung (thấy khi ảnh không phủ kín)
              if (widget.background != null)
                Positioned.fromRect(
                  rect: frameRect,
                  child: widget.frame.shape == CropShape.circle
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.background,
                          ),
                        )
                      : ColoredBox(color: widget.background!),
                )
              else
                Positioned.fromRect(
                  rect: frameRect,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      widget.frame.shape == CropShape.circle
                          ? frame.width / 2
                          : 0,
                    ),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: SizedBox(
                          width: coverRect.width,
                          height: coverRect.height,
                          child: RawImage(
                            image: widget.image,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fromRect(
                rect: imageRect,
                child: RawImage(
                  image: widget.image,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FramePainter(
                      frameRect,
                      circle: widget.frame.shape == CropShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Làm tối phần ngoài khung, viền khung và lưới chia ba
class _FramePainter extends CustomPainter {
  _FramePainter(this.frame, {required this.circle});

  final Rect frame;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = Path();
    if (circle) {
      shape.addOval(frame);
    } else {
      shape.addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(12)));
    }
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addPath(shape, Offset.zero);
    canvas.drawPath(outside, Paint()..color = const Color(0xB3000000));

    canvas.save();
    canvas.clipPath(shape);

    final grid = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = frame.left + frame.width * i / 3;
      final y = frame.top + frame.height * i / 3;
      canvas.drawLine(Offset(x, frame.top), Offset(x, frame.bottom), grid);
      canvas.drawLine(Offset(frame.left, y), Offset(frame.right, y), grid);
    }
    canvas.restore();
    canvas.drawPath(
      shape,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.frame != frame || old.circle != circle;
}
