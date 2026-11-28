import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

/// Bìa của người dùng thường: nền xanh thương hiệu cố định, hoạ tiết các ô
/// bo góc xoay nghiêng (đậm hơn nền một chút) để không bị trống
class ProfilePlainCover extends StatelessWidget {
  const ProfilePlainCover({super.key});

  @override
  Widget build(BuildContext context) => const ClipRect(
    child: CustomPaint(
      painter: _TilePatternPainter(),
      child: SizedBox.expand(),
    ),
  );
}

class _TilePatternPainter extends CustomPainter {
  const _TilePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.actionPrimary,
    );
    final fill = Paint()..color = const Color(0x1A000000);
    final stroke = Paint()
      ..color = const Color(0x26000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const step = 46.0, tile = 34.0;
    var row = 0;
    for (var y = -tile; y < size.height + tile; y += step * 0.8, row++) {
      var col = 0;
      for (
        var x = -tile + (row.isOdd ? step / 2 : 0);
        x < size.width + tile;
        x += step, col++
      ) {
        // Góc xoay giả ngẫu nhiên theo vị trí, cố định giữa các lần vẽ
        final angle = (((row * 7 + col * 13) % 9) - 4) * 0.09;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: tile,
            height: tile * 0.78,
          ),
          const Radius.circular(7),
        );
        if ((row + col) % 3 == 0) canvas.drawRRect(rect, fill);
        canvas.drawRRect(rect, stroke);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_TilePatternPainter oldDelegate) => false;
}
