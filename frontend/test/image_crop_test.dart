import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/image_crop/image_crop.dart';
import 'package:restore/shared/widgets/image_crop/image_crop_view.dart';

Future<Uint8List> testPng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<Uint8List?> _cropThroughPage(
  WidgetTester tester,
  CropFrame frame,
  Uint8List source,
) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  Uint8List? result;
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await ImageCropView.open(
                context,
                source,
                frame: frame,
                title: 'Cắt ảnh',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // giải mã ảnh chạy thật (bất đồng bộ)
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
  expect(find.text('Cắt ảnh'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('image-crop-fit')));
  await tester.pump();
  await tester.drag(
    find.byKey(const ValueKey('image-crop-area')),
    const Offset(40, 0),
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('image-crop-fill')));
  await tester.pump();
  await tester.runAsync(() async {
    await tester.tap(find.text('Dùng ảnh này'));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return result;
}

Future<List<int>> _size(WidgetTester tester, Uint8List bytes) async {
  final decoded = (await tester.runAsync(() => decodeImageFromList(bytes)))!;
  return [decoded.width, decoded.height];
}

void main() {
  test('poster frame: cover fills, contain leaves a gap, clamps', () {
    const image = Size(1600, 1200);
    const frame = CropFrame.poster;
    final cover = ImageCropTransform.cover(image, frame);
    final rect = cover.imageRect(image, const Size(1200, 600));
    expect(rect.width, closeTo(1200, 0.01));
    expect(rect.height, closeTo(900, 0.01));
    expect(cover.leavesGap(image, frame), isFalse);
    expect(
      ImageCropTransform.contain(image, frame).leavesGap(image, frame),
      isTrue,
    );

    // kéo quá mép thì bị giữ lại để ảnh vẫn phủ kín khung
    final moved = cover
        .copyWith(center: const Offset(0.4, 0.4))
        .clamped(image, frame);
    expect(moved.center.dx, 0);
    expect(moved.center.dy, closeTo(0.125, 0.0001));
    expect(
      cover.copyWith(scale: 1).clamped(image, frame).scale,
      ImageCropTransform.maxScale(image, frame),
    );
  });

  test('avatar frame is square: a wide photo covers by height', () {
    const image = Size(1600, 800);
    const frame = CropFrame.avatar;
    final cover = ImageCropTransform.cover(image, frame);
    final rect = cover.imageRect(image, const Size(512, 512));
    expect(rect.height, closeTo(512, 0.01));
    expect(rect.width, closeTo(1024, 0.01));
    // kéo ngang được tới mép ảnh, dọc thì không
    final moved = cover
        .copyWith(center: const Offset(0.9, 0.3))
        .clamped(image, frame);
    expect(moved.center.dx, closeTo(0.5, 0.0001));
    expect(moved.center.dy, 0);
  });

  testWidgets('crop page renders a 1200×600 poster', (tester) async {
    final source = (await tester.runAsync(() => testPng(800, 800)))!;
    final result = await _cropThroughPage(tester, CropFrame.poster, source);
    expect(result, isNotNull);
    expect(await _size(tester, result!), [1200, 600]);
  });

  testWidgets('crop page renders a 512×512 avatar', (tester) async {
    final source = (await tester.runAsync(() => testPng(900, 600)))!;
    final result = await _cropThroughPage(tester, CropFrame.avatar, source);
    expect(result, isNotNull);
    expect(await _size(tester, result!), [512, 512]);
  });

  test('circle fit keeps all four corners inside the circle', () {
    const image = Size(900, 300);
    const frame = CropFrame.avatar;
    final fit = ImageCropTransform.contain(image, frame);
    final rect = fit.imageRect(image, const Size(1, 1));
    final corner = rect.topLeft - const Offset(0.5, 0.5);
    expect(corner.distance, closeTo(0.5, 0.0001));
    expect(ImageCropTransform.minScale(image, frame), lessThan(fit.scale));
  });

  test('finds plain borders, edge colour and fills the gap', () async {
    final logo = await _logo();
    final rect = await detectUniformBorders(logo);
    expect(rect, isNotNull);
    expect(rect!.top, 100);
    expect(rect.bottom, 400);
    final trimmed = await cropImage(logo, rect);
    expect(await sampleEdgeColor(trimmed), const Color(0xFFFFFFFF));
    // ảnh một màu thì không có gì để bỏ
    final plain = await decodeImageFromList(await testPng(200, 200));
    expect(await detectUniformBorders(plain), isNull);

    const frame = CropFrame.avatar;
    final size = Size(trimmed.width.toDouble(), trimmed.height.toDouble());
    final png = await renderImageCrop(
      trimmed,
      ImageCropTransform.contain(size, frame),
      frame,
      background: const Color(0xFF000000),
    );
    final out = await decodeImageFromList(png);
    final pixels = (await out.toByteData())!;
    // góc trên trái là nền đen đã chọn
    expect(pixels.getUint32(0), 0x000000FF);
  });
}

/// Logo giả: dải xám trên dưới, giữa nền trắng có thanh xanh
Future<ui.Image> _logo() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 600, 500),
    Paint()..color = const Color(0xFFC9C9C9),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 100, 600, 300),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.drawRect(
    const Rect.fromLTWH(150, 220, 300, 60),
    Paint()..color = const Color(0xFF1428A0),
  );
  return recorder.endRecording().toImage(600, 500);
}
