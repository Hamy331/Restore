import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/listings/data/listing_repository.dart';
import 'package:restore/modules/listings/domain/entities/listing_preview.dart';
import 'package:restore/modules/listings/presentation/bloc/listing_form_cubit.dart';
import 'package:restore/modules/listings/presentation/bloc/manage_listings_cubit.dart';

Map<String, dynamic> _item(String status) => {
  'id': 'mine-1',
  'title': 'Bàn gỗ sồi',
  'description': 'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
  'price': '1200000',
  'condition': 'USED_GOOD',
  'isNegotiable': true,
  'images': <String>[],
  'status': status,
  'createdAt': '2026-10-05T00:00:00.000Z',
  'category': {'id': 'furniture', 'name': 'Nội thất'},
  'owner': {'id': 'user-1', 'fullName': 'Lan Nguyễn'},
};

class _OwnedRepository extends ListingRepository {
  _OwnedRepository() : super(dio: Dio());
  String status = 'AVAILABLE';
  String? lastFilter;
  String? lastChangedTo;
  String? savedTitle;
  bool deletedDraft = false;

  @override
  Future<ListingPage> mine({int page = 1, String? status}) async {
    lastFilter = status;
    final items = status == null || status == this.status
        ? [ListingPreview.fromJson(_item(this.status))]
        : <ListingPreview>[];
    return ListingPage(items, items.length, 1);
  }

  @override
  Future<ListingPreview> changeStatus(String id, String status) async {
    expect(id, 'mine-1');
    lastChangedTo = status;
    this.status = status;
    return ListingPreview.fromJson(_item(status));
  }

  @override
  Future<void> deleteDraft(String id) async {
    expect(id, 'mine-1');
    deletedDraft = true;
    status = 'DELETED';
  }

  @override
  Future<ListingPreview> getMine(String id) async =>
      ListingPreview.fromJson(_item(status));

  @override
  Future<ListingPreview> update(
    String id, {
    required String title,
    required String description,
    required String price,
    required String condition,
    required String categoryId,
    required bool isNegotiable,
  }) async {
    expect(id, 'mine-1');
    expect(categoryId, 'furniture');
    savedTitle = title;
    return ListingPreview.fromJson({..._item(status), 'title': title});
  }
}

void main() {
  test('draft tab filters and deletion refreshes the list', () async {
    final repository = _OwnedRepository()..status = 'DRAFT';
    final cubit = ManageListingsCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.statusChanged(ManagedListingStatus.draft);
    expect(repository.lastFilter, 'DRAFT');
    expect(cubit.state.items.single.status, 'DRAFT');
    expect(await cubit.deleteDraft(cubit.state.items.single), true);
    expect(repository.deletedDraft, true);
    expect(cubit.state.items, isEmpty);
  });
  test(
    'my listings load real status filters and refresh after hiding',
    () async {
      final repository = _OwnedRepository();
      final cubit = ManageListingsCubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.items.single.id, 'mine-1');
      expect(repository.lastFilter, null);
      expect(
        await cubit.changeStatus(cubit.state.items.single, 'HIDDEN'),
        true,
      );
      expect(repository.lastChangedTo, 'HIDDEN');
      expect(cubit.state.items.single.status, 'HIDDEN');
      await cubit.statusChanged(ManagedListingStatus.visible);
      expect(repository.lastFilter, 'AVAILABLE');
      expect(cubit.state.items, isEmpty);
    },
  );

  test('edit loads owned listing and saves changed fields', () async {
    final repository = _OwnedRepository();
    final form = ListingFormCubit(
      editing: true,
      listingId: 'mine-1',
      repository: repository,
    );
    addTearDown(form.close);
    await form.load();
    expect(form.state.title, 'Bàn gỗ sồi');
    expect(form.state.price, '1200000');
    form.titleChanged('Bàn gỗ sồi mới');
    await form.submit();
    expect(repository.savedTitle, 'Bàn gỗ sồi mới');
    expect(form.state.createdId, 'mine-1');
  });

  test('update and status requests use owned-listing endpoints', () async {
    final paths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add('${options.method} ${options.path}');
          if (options.method == 'PATCH') {
            expect(options.data, {'status': 'SOLD'});
          }
          if (options.method == 'PUT') {
            expect(options.data['title'], 'Bàn gỗ sồi mới');
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'data': _item('AVAILABLE')},
            ),
          );
        },
      ),
    );
    final repository = ListingRepository(dio: dio);
    await repository.getMine('mine-1');
    await repository.update(
      'mine-1',
      title: 'Bàn gỗ sồi mới',
      description: 'Bàn gỗ sồi còn chắc chắn, dùng tốt.',
      price: '1200000',
      condition: 'USED_GOOD',
      categoryId: 'furniture',
      isNegotiable: true,
    );
    await repository.changeStatus('mine-1', 'SOLD');
    expect(paths, [
      'GET /listings/mine/mine-1',
      'PUT /listings/mine-1',
      'PATCH /listings/mine-1/status',
    ]);
  });
}
