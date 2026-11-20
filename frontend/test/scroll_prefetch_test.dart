import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';

void main() {
  testWidgets('dựng sẵn thẻ nằm dưới màn hình để ảnh tải trước', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Widget list({ScrollCacheExtent? cacheExtent}) => MaterialApp(
      home: CustomScrollView(
        scrollCacheExtent: cacheExtent,
        slivers: [
          SliverList.builder(
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(height: 280, child: Text('tin $i')),
          ),
        ],
      ),
    );

    // Mặc định Flutter chỉ dựng thêm 250 px (tới 1050 px): thẻ thứ 5 (từ
    // 1120 px) chưa được dựng
    await tester.pumpWidget(list());
    expect(find.text('tin 4', skipOffstage: false), findsNothing);

    // Dựng thêm 1200 px (tới 2000 px): thẻ thứ 5 đến thứ 8 đã có sẵn
    await tester.pumpWidget(list(cacheExtent: AppScroll.prefetchCacheExtent));
    expect(find.text('tin 4', skipOffstage: false), findsOneWidget);
    expect(find.text('tin 7', skipOffstage: false), findsOneWidget);
    expect(find.text('tin 4'), findsNothing); // vẫn nằm ngoài màn hình
  });

  testWidgets('gọi tải trang tiếp khi còn cách cuối khoảng tải trước', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppLoadMoreListener(
          onLoadMore: () => loads++,
          child: ListView(
            children: [
              for (var i = 0; i < 10; i++) const SizedBox(height: 280),
            ],
          ),
        ),
      ),
    );
    // Tổng 2800 px, màn 800 px: còn 2000 px phía dưới, chưa tải
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(loads, 0);
    // Còn ~1000 px (< 1200) thì tải, chưa cần cuộn chạm đáy
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(loads, greaterThan(0));
  });
}
