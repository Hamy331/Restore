import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/shared/utils/image_cache/app_image_disk_cache.dart';
import 'package:restore/shared/utils/image_cache/app_network_image.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// PNG 1x1 hợp lệ
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  tearDown(() {
    AppNetworkImage.debugFetcher = null;
    imageCache
      ..clear()
      ..clearLiveImages();
  });

  group('AppLocalImage ảnh mạng', () {
    testWidgets('cuộn ra rồi quay lại không tải lại ảnh', (tester) async {
      var fetches = 0;
      AppNetworkImage.debugFetcher = (url) async {
        fetches++;
        return _png;
      };
      const url = 'https://cdn.example/a.png';
      Widget page(bool show) => MaterialApp(
        home: Scaffold(
          body: show
              ? const SizedBox(
                  width: 100,
                  height: 100,
                  child: AppLocalImage(path: url, cacheWidth: 200),
                )
              : const SizedBox(),
        ),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(page(true));
        for (var i = 0; i < 20 && fetches == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        // Chờ giải mã xong để ảnh vào ImageCache
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(fetches, 1);
      expect(find.byType(Image), findsOneWidget);

      // Widget bị hủy (cuộn ra khỏi màn hình) rồi tạo lại
      await tester.pumpWidget(page(false));
      await tester.pumpWidget(page(true));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(fetches, 1);
    });

    testWidgets('tải lỗi thì hiện icon dự phòng, không vòng xoay', (
      tester,
    ) async {
      AppNetworkImage.debugFetcher = (url) async => throw Exception('404');
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: AppLocalImage(
              path: 'https://cdn.example/missing.png',
              fallbackIcon: Icons.broken_image,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    test('cùng URL là cùng khóa cache bộ nhớ', () {
      expect(
        const AppNetworkImage('https://a/x.png'),
        const AppNetworkImage('https://a/x.png'),
      );
      expect(
        const AppNetworkImage('https://a/x.png') ==
            const AppNetworkImage('https://a/y.png'),
        isFalse,
      );
    });
  });

  group('AppImageDiskCache', () {
    late Directory dir;
    late AppImageDiskCache cache;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('app_images_test');
      cache = AppImageDiskCache.withDirectory(dir);
    });

    tearDown(() => dir.delete(recursive: true));

    test('ghi rồi đọc lại đúng bytes', () async {
      expect(await cache.read('https://a/x.png'), isNull);
      await cache.write('https://a/x.png', _png);
      expect(await cache.read('https://a/x.png'), _png);
      expect(await cache.read('https://a/y.png'), isNull);
    });

    test('khóa ổn định và khác nhau theo URL', () {
      final a = AppImageDiskCache.keyOf('https://a/x.png');
      expect(AppImageDiskCache.keyOf('https://a/x.png'), a);
      expect(AppImageDiskCache.keyOf('https://a/y.png'), isNot(a));
      expect(a, matches(RegExp(r'^[0-9a-f]{16}_[0-9a-f]+$')));
    });

    test('dọn file quá hạn', () async {
      await cache.write('https://a/old.png', _png);
      await cache.write('https://a/new.png', _png);
      final old = File(
        '${dir.path}/${AppImageDiskCache.keyOf('https://a/old.png')}',
      );
      await old.setLastModified(
        DateTime.now().subtract(
          AppImageDiskCache.maxAge + const Duration(days: 1),
        ),
      );
      await cache.prune();
      expect(await old.exists(), isFalse);
      expect(await cache.read('https://a/new.png'), _png);
    });
  });
}
