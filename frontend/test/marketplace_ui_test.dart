import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/chat/views/messages_view.dart';
import 'package:restore/modules/home/views/home_view.dart';
import 'package:restore/modules/listings/presentation/views/create_listing_view.dart';
import 'package:restore/modules/listings/presentation/views/manage_listings_view.dart';

void main() {
  const sizes = <Size>[
    Size(360, 812),
    Size(375, 812),
    Size(412, 915),
    Size(768, 1024),
  ];

  testWidgets('home matches supported mobile and tablet widths', (
    tester,
  ) async {
    for (final size in sizes) {
      await _pumpAt(tester, size, const HomeView());
      expect(find.text('Đồ tốt đổi chủ'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'home viewport: $size');
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('messages matches supported mobile and tablet widths', (
    tester,
  ) async {
    for (final size in sizes) {
      await _pumpAt(tester, size, const MessagesView());
      expect(find.text('Tin nhắn'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'messages viewport: $size',
      );
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('selling screens match supported widths', (tester) async {
    for (final size in sizes) {
      await _pumpAt(tester, size, const ManageListingsView());
      expect(find.text('Quản lý tin'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'manage viewport: $size');

      await _pumpAt(tester, size, const CreateListingView());
      expect(find.text('Ảnh sản phẩm  ·  2/10'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'create viewport: $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}
