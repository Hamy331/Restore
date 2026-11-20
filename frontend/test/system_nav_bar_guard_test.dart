import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/shared/widgets/app_system_nav_bar_guard.dart';

void main() {
  late MediaQueryData inner;

  Widget app(double bottom, {double keyboard = 0}) => MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      padding: EdgeInsets.only(bottom: keyboard > 0 ? 0 : bottom),
      viewPadding: EdgeInsets.only(bottom: bottom),
      viewInsets: EdgeInsets.only(bottom: keyboard),
    ),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: AppSystemNavBarGuard(
        child: Builder(
          builder: (context) {
            inner = MediaQuery.of(context);
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  final guard = find.byKey(const ValueKey('system-nav-bar-guard'));

  testWidgets('máy thanh 3 nút: có dải trắng, nội dung không bị che', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(app(48));
    expect(guard, findsOneWidget);
    expect(tester.getSize(guard).height, 48);
    expect(tester.getTopLeft(guard).dy, 800 - 48);
    expect(inner.padding.bottom, 0);
    expect(inner.viewPadding.bottom, 0);

    // Bàn phím 300 (tính từ đáy màn hình) còn 252 phía trên dải trắng
    await tester.pumpWidget(app(48, keyboard: 300));
    expect(inner.viewInsets.bottom, 252);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('máy dùng cử chỉ hoặc iOS: giữ tràn viền như cũ', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(app(24));
    expect(guard, findsNothing);
    expect(inner.padding.bottom, 24);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(app(48));
    expect(guard, findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
