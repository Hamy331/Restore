import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/listings/views/listing_detail_view.dart';

void main() {
  testWidgets('listing detail shows sample item and toggles saved state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ListingDetailView(listingId: '101')),
    );

    expect(find.text('Máy ảnh Fujifilm X-T20 kèm kit'), findsOneWidget);
    expect(find.text('7.900.000 đ'), findsOneWidget);

    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Đã lưu'), findsOneWidget);
  });

  testWidgets('unknown listing does not display another seller item', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ListingDetailView(listingId: 'unknown')),
    );

    expect(find.text('Không tìm thấy tin đăng.'), findsOneWidget);
    expect(find.text('Máy ảnh Fujifilm X-T20 kèm kit'), findsNothing);
  });
}
