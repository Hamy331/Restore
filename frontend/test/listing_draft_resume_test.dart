import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_bloc.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_event.dart';
import 'package:restore/modules/listings/models/listing_draft.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';

void main() {
  test('reopening an owner draft restores its ID and entered fields', () async {
    final repository = MockListingsRepository(latency: Duration.zero);
    final saved = await repository.saveDraft(
      const ListingDraft(
        title: 'Bàn gỗ đã lưu',
        description: 'Nội dung đang soạn',
      ),
      null,
    );
    final bloc = CreateListingBloc(
      listingsRepository: repository,
      categoryRepository: MockCategoryRepository(),
    );
    addTearDown(bloc.close);
    final resumed = bloc.stream.firstWhere(
      (state) => state.draft.id == saved.id,
    );
    bloc.add(DraftRequested(saved.id!));
    final state = await resumed;
    expect(state.draft.title, saved.title);
    expect(state.draft.description, saved.description);
    expect(state.isLoadingDraft, isFalse);
    expect(state.draftLoadFailed, isFalse);
    await repository.deleteDraft(saved.id!);
  });
}
