import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Kích thước poster xuất ra (tỉ lệ 2:1, giống banner trang chủ)
const Size posterOutputSize = Size(1200, 600);

/// Vị trí ảnh trong khung cắt, tính theo "đơn vị khung": khung rộng 1, cao 0.5.
/// [scale] = số đơn vị khung cho mỗi px ảnh; [center] = tâm ảnh so với tâm khung.
class PosterCropTransform {
  const PosterCropTransform({required this.scale, this.center = Offset.zero});

  final double scale;
  final Offset center;

  static const double frameHeight = 0.5;

  /// Ảnh vừa khít trong khung (thấy toàn bộ ảnh, phần trống là nền mờ)
  static double containScale(Size image) =>
      math.min(1 / image.width, frameHeight / image.height);

  /// Ảnh phủ kín khung (cắt bớt phần thừa)
  static double coverScale(Size image) =>
      math.max(1 / image.width, frameHeight / image.height);

  static double minScale(Size image) => containScale(image);
  static double maxScale(Size image) => coverScale(image) * 5;

  factory PosterCropTransform.cover(Size image) =>
      PosterCropTransform(scale: coverScale(image));

  factory PosterCropTransform.contain(Size image) =>
      PosterCropTransform(scale: containScale(image));

  /// Giữ tỉ lệ trong giới hạn; chiều nào ảnh lớn hơn khung thì ảnh phải phủ
  /// kín khung theo chiều đó, chiều nào nhỏ hơn thì ảnh không ra khỏi khung.
  PosterCropTransform clamped(Size image) {
    final s = scale.clamp(minScale(image), maxScale(image)).toDouble();
    double axis(double value, double imageSize, double frameSize) {
      final limit = (imageSize - frameSize).abs() / 2;
      return value.clamp(-limit, limit).toDouble();
    }

    return PosterCropTransform(
      scale: s,
      center: Offset(
        axis(center.dx, image.width * s, 1),
        axis(center.dy, image.height * s, frameHeight),
      ),
    );
  }

  /// Hình chữ nhật của ảnh trong khung có kích thước [frame]
  Rect imageRect(Size image, Size frame) {
    final unit = frame.width;
    final w = image.width * scale * unit, h = image.height * scale * unit;
    final cx = frame.width / 2 + center.dx * unit;
    final cy = frame.height / 2 + center.dy * unit;
    return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
  }

  /// Ảnh không phủ kín khung (cần nền mờ)
  bool leavesGap(Size image) {
    final rect = imageRect(image, const Size(1, frameHeight));
    return rect.left > 0.0001 ||
        rect.top > 0.0001 ||
        rect.right < 0.9999 ||
        rect.bottom < frameHeight - 0.0001;
  }

  PosterCropTransform copyWith({double? scale, Offset? center}) =>
      PosterCropTransform(
        scale: scale ?? this.scale,
        center: center ?? this.center,
      );
}

/// Vẽ phần ảnh trong khung ra ảnh 1200×600: nền là chính ảnh phủ kín và làm
/// mờ (lấp phần trống khi thu nhỏ), trên là ảnh theo vị trí người dùng chọn.
Future<Uint8List> renderPosterCrop(
  ui.Image image,
  PosterCropTransform transform,
) async {
  final size = Size(image.width.toDouble(), image.height.toDouble());
  final out = posterOutputSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & out);
  final source = Offset.zero & size;
  final paint = Paint()..filterQuality = FilterQuality.high;

  if (transform.leavesGap(size)) {
    final cover = PosterCropTransform.cover(size).imageRect(size, out);
    canvas.drawRect(
      Offset.zero & out,
      Paint()..color = const Color(0xFF29231B),
    );
    canvas.saveLayer(
      Offset.zero & out,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
    );
    canvas.drawImageRect(image, source, cover.inflate(60), paint);
    canvas.restore();
    // phủ một lớp tối nhẹ để ảnh chính nổi hơn nền
    canvas.drawRect(
      Offset.zero & out,
      Paint()..color = const Color(0x33000000),
    );
  }
  canvas.drawImageRect(image, source, transform.imageRect(size, out), paint);

  final picture = recorder.endRecording();
  final rendered = await picture.toImage(out.width.toInt(), out.height.toInt());
  picture.dispose();
  final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
  rendered.dispose();
  return data!.buffer.asUint8List();
}
