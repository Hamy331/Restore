import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/listings/views/manage_listings_view.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';
import 'package:restore/modules/listings/models/listing_draft.dart';

void main() {
  testWidgets('Tin cua toi shows saved draft and owner actions', (
    tester,
  ) async {
    final repository = MockListingsRepository(latency: Duration.zero);
    final draft = (await tester.runAsync(
      () => repository.saveDraft(
        const ListingDraft(title: 'Ban go da luu'),
        null,
      ),
    ))!;
    await tester.pumpWidget(
      MaterialApp(home: ManageListingsView(repository: repository)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Ban go da luu'), findsOneWidget);
    expect(find.text('Tiếp tục nháp'), findsOneWidget);
    expect(find.text('Xóa nháp'), findsOneWidget);
    expect(find.text('Chưa có giá'), findsOneWidget);
    expect(find.text('Ẩn tin'), findsNothing);
    await repository.deleteDraft(draft.id!);
  });
}
