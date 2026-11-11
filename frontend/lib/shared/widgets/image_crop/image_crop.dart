import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Hình dạng khung cắt. Ảnh xuất ra luôn là hình chữ nhật; khung tròn chỉ là
/// cách hiển thị (ảnh đại diện được bo tròn khi hiện).
enum CropShape { rect, circle }

/// Khung cắt cố định: tỉ lệ cao / rộng, kích thước ảnh xuất ra và hình dạng.
class CropFrame {
  const CropFrame({
    required this.aspect,
    required this.output,
    this.shape = CropShape.rect,
  });

  /// Chiều cao khung khi chiều rộng là 1 (2:1 → 0.5, vuông → 1)
  final double aspect;
  final Size output;
  final CropShape shape;

  /// Poster shop 2:1, giống banner trang chủ
  static const poster = CropFrame(aspect: 0.5, output: Size(1200, 600));

  /// Ảnh đại diện / logo: vuông, hiển thị trong khung tròn
  static const avatar = CropFrame(
    aspect: 1,
    output: Size(512, 512),
    shape: CropShape.circle,
  );
}

/// Vị trí ảnh trong khung cắt, tính theo "đơn vị khung": khung rộng 1, cao
/// [CropFrame.aspect]. [scale] = số đơn vị khung cho mỗi px ảnh; [center] =
/// tâm ảnh so với tâm khung.
class ImageCropTransform {
  const ImageCropTransform({required this.scale, this.center = Offset.zero});

  final double scale;
  final Offset center;

  /// Ảnh vừa khít trong khung (thấy toàn bộ ảnh, phần trống là nền). Khung
  /// tròn thì cả bốn góc ảnh phải nằm trong vòng tròn (logo chữ dài không bị
  /// cắt mất hai đầu).
  static double containScale(Size image, CropFrame frame) =>
      frame.shape == CropShape.circle
      ? 1 / math.sqrt(image.width * image.width + image.height * image.height)
      : math.min(1 / image.width, frame.aspect / image.height);

  /// Ảnh phủ kín khung (cắt bớt phần thừa)
  static double coverScale(Size image, CropFrame frame) =>
      math.max(1 / image.width, frame.aspect / image.height);

  /// Khung tròn cho thu nhỏ thêm để logo có lề quanh mép
  static double minScale(Size image, CropFrame frame) =>
      containScale(image, frame) * (frame.shape == CropShape.circle ? 0.6 : 1);
  static double maxScale(Size image, CropFrame frame) =>
      coverScale(image, frame) * 5;

  factory ImageCropTransform.cover(Size image, CropFrame frame) =>
      ImageCropTransform(scale: coverScale(image, frame));

  factory ImageCropTransform.contain(Size image, CropFrame frame) =>
      ImageCropTransform(scale: containScale(image, frame));

  /// Giữ tỉ lệ trong giới hạn; chiều nào ảnh lớn hơn khung thì ảnh phải phủ
  /// kín khung theo chiều đó, chiều nào nhỏ hơn thì ảnh không ra khỏi khung.
  ImageCropTransform clamped(Size image, CropFrame frame) {
    final s = scale
        .clamp(minScale(image, frame), maxScale(image, frame))
        .toDouble();
    double axis(double value, double imageSize, double frameSize) {
      final limit = (imageSize - frameSize).abs() / 2;
      return value.clamp(-limit, limit).toDouble();
    }

    return ImageCropTransform(
      scale: s,
      center: Offset(
        axis(center.dx, image.width * s, 1),
        axis(center.dy, image.height * s, frame.aspect),
      ),
    );
  }

  /// Hình chữ nhật của ảnh trong khung có kích thước [frame] (px)
  Rect imageRect(Size image, Size frame) {
    final unit = frame.width;
    final w = image.width * scale * unit, h = image.height * scale * unit;
    final cx = frame.width / 2 + center.dx * unit;
    final cy = frame.height / 2 + center.dy * unit;
    return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
  }

  /// Ảnh không phủ kín khung (cần nền mờ)
  bool leavesGap(Size image, CropFrame frame) {
    final rect = imageRect(image, Size(1, frame.aspect));
    return rect.left > 0.0001 ||
        rect.top > 0.0001 ||
        rect.right < 0.9999 ||
        rect.bottom < frame.aspect - 0.0001;
  }

  /// Mỗi px ảnh gốc bị phóng lên hơn 1,5 px ở ảnh xuất ra thì dễ mờ
  bool lowRes(CropFrame frame) => scale * frame.output.width > 1.5;

  ImageCropTransform copyWith({double? scale, Offset? center}) =>
      ImageCropTransform(
        scale: scale ?? this.scale,
        center: center ?? this.center,
      );
}

/// Phần nội dung của ảnh sau khi bỏ các dải viền một màu ở mép (VD logo
/// được chụp màn hình kèm hai dải xám trên dưới). Một hàng / cột mép được coi
/// là viền khi mọi pixel gần như cùng màu với pixel đầu của dải đó. Trả về
/// `null` nếu không có viền đáng kể (dưới 2% mỗi cạnh).
Future<Rect?> detectUniformBorders(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final w = image.width, h = image.height;
  if (data == null || w < 8 || h < 8) return null;
  int px(int x, int y) => data.getUint32((y * w + x) * 4);
  bool close(int a, int b) {
    for (var shift = 0; shift < 32; shift += 8) {
      if (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF) case final d
          when d.abs() > 18) {
        return false;
      }
    }
    return true;
  }

  final stepX = math.max(1, w ~/ 300), stepY = math.max(1, h ~/ 300);
  bool rowUniform(int y, int ref) {
    for (var x = 0; x < w; x += stepX) {
      if (!close(px(x, y), ref)) return false;
    }
    return true;
  }

  bool colUniform(int x, int ref, int top, int bottom) {
    for (var y = top; y <= bottom; y += stepY) {
      if (!close(px(x, y), ref)) return false;
    }
    return true;
  }

  var top = 0, bottom = h - 1;
  final topRef = px(0, 0), bottomRef = px(0, h - 1);
  while (top < bottom && rowUniform(top, topRef)) {
    top++;
  }
  while (bottom > top && rowUniform(bottom, bottomRef)) {
    bottom--;
  }
  var left = 0, right = w - 1;
  if (bottom - top > 4) {
    final leftRef = px(0, top), rightRef = px(w - 1, top);
    while (left < right && colUniform(left, leftRef, top, bottom)) {
      left++;
    }
    while (right > left && colUniform(right, rightRef, top, bottom)) {
      right--;
    }
  }
  // cả ảnh một màu, hoặc bỏ đi quá ít thì không cần
  if (right - left < w * 0.1 || bottom - top < h * 0.1) return null;
  final trimmed =
      top > h * 0.02 ||
      h - 1 - bottom > h * 0.02 ||
      left > w * 0.02 ||
      w - 1 - right > w * 0.02;
  if (!trimmed) return null;
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right + 1.0,
    bottom + 1.0,
  );
}

/// Cắt [image] theo [rect] (px) thành ảnh mới
Future<ui.Image> cropImage(ui.Image image, Rect rect) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    rect,
    Offset.zero & rect.size,
    Paint()..filterQuality = FilterQuality.none,
  );
  final picture = recorder.endRecording();
  final result = await picture.toImage(rect.width.round(), rect.height.round());
  picture.dispose();
  return result;
}

/// Màu nền ở viền ảnh (VD nền trắng của logo), dùng làm màu nền "Theo ảnh".
/// Lấy màu xuất hiện nhiều nhất ở viền (không lấy trung bình để nét logo sát
/// mép không làm lệch màu). Pixel trong suốt được tính như nền trắng.
Future<Color> sampleEdgeColor(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final w = image.width, h = image.height;
  if (data == null || w == 0 || h == 0) return const Color(0xFFFFFFFF);
  // gom màu theo ô 16 mức mỗi kênh; mỗi ô giữ tổng r, g, b và số pixel
  final buckets = <int, List<double>>{};
  void add(int x, int y) {
    final i = (y * w + x) * 4;
    final a = data.getUint8(i + 3) / 255;
    final r = data.getUint8(i) * a + 255 * (1 - a);
    final g = data.getUint8(i + 1) * a + 255 * (1 - a);
    final b = data.getUint8(i + 2) * a + 255 * (1 - a);
    final key = (r ~/ 16) << 8 | (g ~/ 16) << 4 | (b ~/ 16);
    final bucket = buckets.putIfAbsent(key, () => [0, 0, 0, 0]);
    bucket[0] += r;
    bucket[1] += g;
    bucket[2] += b;
    bucket[3]++;
  }

  // dải viền dày ~2% mỗi cạnh, lấy cách quãng cho nhanh
  final band = math.max(1, (math.min(w, h) * 0.02).round());
  final step = math.max(1, (math.max(w, h) / 200).round());
  for (var d = 0; d < band; d++) {
    for (var x = 0; x < w; x += step) {
      add(x, d);
      add(x, h - 1 - d);
    }
    for (var y = 0; y < h; y += step) {
      add(d, y);
      add(w - 1 - d, y);
    }
  }
  final top = buckets.values.reduce((a, b) => a[3] >= b[3] ? a : b);
  return Color.fromARGB(
    255,
    (top[0] / top[3]).round(),
    (top[1] / top[3]).round(),
    (top[2] / top[3]).round(),
  );
}

/// Vẽ phần ảnh trong khung ra ảnh PNG cỡ [CropFrame.output]. Phần trống (khi
/// thu nhỏ) được tô bằng [background], hoặc khi `null` là chính ảnh phủ kín
/// và làm mờ; trên là ảnh theo vị trí người dùng chọn.
Future<Uint8List> renderImageCrop(
  ui.Image image,
  ImageCropTransform transform,
  CropFrame frame, {
  Color? background,
}) async {
  final size = Size(image.width.toDouble(), image.height.toDouble());
  final out = frame.output;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & out);
  final source = Offset.zero & size;
  final paint = Paint()..filterQuality = FilterQuality.high;

  if (background != null) {
    canvas.drawRect(Offset.zero & out, Paint()..color = background);
  } else if (transform.leavesGap(size, frame)) {
    final cover = ImageCropTransform.cover(size, frame).imageRect(size, out);
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
