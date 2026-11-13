import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/data/models/listing_revision_model.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_bloc.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_event.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_state.dart';
import 'package:restore/modules/listings/repositories/category_repository.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';
import 'package:restore/modules/listings/repositories/posting_quota_repository.dart';

CreateListingBloc _bloc(ListingsRepository repository) => CreateListingBloc(
  listingsRepository: repository,
  categoryRepository: MockCategoryRepository(latency: Duration.zero),
  postingQuotaRepository: MockPostingQuotaRepository(latency: Duration.zero),
);

Future<CreateListingState> _until(
  CreateListingBloc bloc,
  bool Function(CreateListingState) test,
) => test(bloc.state) ? Future.value(bloc.state) : bloc.stream.firstWhere(test);

void main() {
  test('pendingEdit from the API: content is the edited listing', () {
    final listing = ListingModel.fromJson({
      'id': 'x1',
      'ownerId': 'u1',
      'title': 'Đèn bàn gỗ cũ',
      'description': 'Mô tả cũ đủ dài',
      'price': '250000',
      'status': 'AVAILABLE',
      'categoryId': 'other',
      'images': ['/api/v1/listings/media/a.png'],
      'updatedAt': '2026-11-12T10:00:00.000Z',
      'pendingEdit': {
        'status': 'REJECTED',
        'reviewReason': 'Ảnh mờ',
        'submittedAt': '2026-11-12T11:00:00.000Z',
        'updatedAt': '2026-11-12T11:30:00.000Z',
        'title': 'Đèn bàn gỗ sồi',
        'description': 'Mô tả mới đủ dài',
        'price': '200000',
        'images': ['/api/v1/listings/media/b.png'],
      },
    }, apiBaseUrl: 'https://api.test/api/v1');
    expect(listing.title, 'Đèn bàn gỗ cũ');
    final edit = listing.pendingEdit!;
    expect(edit.status, ListingRevisionStatus.rejected);
    expect(edit.reviewReason, 'Ảnh mờ');
    expect(edit.content.title, 'Đèn bàn gỗ sồi');
    expect(edit.content.price, 200000);
    expect(edit.content.status, ListingStatus.available);
    expect(edit.content.images, [
      'https://api.test/api/v1/listings/media/b.png',
    ]);
    expect(edit.content.pendingEdit, isNull);
    expect(edit.content.categoryId, 'other');
  });

  test('a listing without pendingEdit has none', () {
    final listing = ListingModel.fromJson({'id': 'x2', 'title': 'Tin'});
    expect(listing.pendingEdit, isNull);
  });

  test(
    'open an approved listing to edit; a pending edit is reopened, the live listing stays',
    () async {
      final repository = MockListingsRepository(latency: Duration.zero);
      var bloc = _bloc(repository)..add(const ListingEditOpened('l1'));
      var state = await _until(
        bloc,
        (s) => s.openEditStatus == RequestStatus.success,
      );
      final original = state.draft.title;
      expect(state.isEditing, isTrue);
      expect(state.isEditingApproved, isTrue);
      expect(state.draft.id, 'l1');
      expect(state.draft.status, ListingStatus.available);
      expect(state.hasUnsavedChanges, isFalse);

      bloc.add(const TitleChanged('Máy ảnh Canon AE-1 đã sửa'));
      state = await _until(bloc, (s) => s.draft.title != original);
      expect(state.hasUnsavedChanges, isTrue);
      await bloc.close();

      // Gửi bản sửa: tin đã duyệt giữ nguyên bản cũ, bản sửa chờ duyệt
      await repository.publish(state.draft, null);
      final live = await repository.getOwned('l1');
      expect(live.title, original);
      expect(live.status, ListingStatus.available);
      expect(live.pendingEdit?.isPending, isTrue);
      expect(live.pendingEdit?.content.title, 'Máy ảnh Canon AE-1 đã sửa');

      // Mở lại: sửa tiếp bản sửa đang chờ
      bloc = _bloc(repository)..add(const ListingEditOpened('l1'));
      state = await _until(
        bloc,
        (s) => s.openEditStatus == RequestStatus.success,
      );
      expect(state.draft.title, 'Máy ảnh Canon AE-1 đã sửa');
      expect(state.editingListing?.pendingEdit?.isPending, isTrue);
      await bloc.close();

      await repository.discardEdit('l1');
      expect((await repository.getOwned('l1')).pendingEdit, isNull);
    },
  );

  test('a listing that cannot be edited fails to open', () async {
    final bloc = _bloc(MockListingsRepository(latency: Duration.zero))
      ..add(const ListingEditOpened('missing-listing'));
    final state = await _until(
      bloc,
      (s) => s.openEditStatus == RequestStatus.failure,
    );
    expect(state.isEditing, isFalse);
    await bloc.close();
  });
}
