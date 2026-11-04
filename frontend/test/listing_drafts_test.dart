import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_bloc.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_event.dart';
import 'package:restore/modules/listings/bloc/create_listing/create_listing_state.dart';
import 'package:restore/modules/listings/models/draft_quota.dart';
import 'package:restore/modules/listings/models/listing_draft.dart';
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
  // Kho nháp giả lập dùng chung (static) giữa các test: dọn trước mỗi test
  setUp(() async {
    final repository = MockListingsRepository(latency: Duration.zero);
    for (final item in (await repository.mine(status: 'DRAFT')).items) {
      await repository.deleteDraft(item.id);
    }
  });

  test('unsaved changes: none for an empty form, tracked after save', () async {
    final repository = MockListingsRepository(latency: Duration.zero);
    final bloc = _bloc(repository);
    expect(bloc.state.hasUnsavedChanges, isFalse);

    bloc.add(const TitleChanged('Xe đạp cũ'));
    await _until(bloc, (state) => state.draft.title == 'Xe đạp cũ');
    expect(bloc.state.hasUnsavedChanges, isTrue);

    bloc.add(const DraftSaveRequested());
    await _until(bloc, (s) => s.saveDraftStatus == RequestStatus.success);
    expect(bloc.state.hasUnsavedChanges, isFalse);
    expect(bloc.state.draft.id, isNotNull);

    // Chỉ khoảng trắng thừa thì không tính là sửa
    bloc.add(const TitleChanged('Xe đạp cũ '));
    await _until(bloc, (state) => state.draft.title == 'Xe đạp cũ ');
    expect(bloc.state.hasUnsavedChanges, isFalse);
    await bloc.close();
  });

  test('drafts list, open a draft to continue, delete a draft', () async {
    final repository = MockListingsRepository(latency: Duration.zero);
    final first = await repository.saveDraft(
      const ListingDraft(title: 'Nháp một', categoryId: 'phones'),
      null,
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final second = await repository.saveDraft(
      const ListingDraft(title: 'Nháp hai'),
      null,
    );

    final bloc = _bloc(repository)..add(const DraftsRequested());
    var state = await _until(
      bloc,
      (s) => s.draftsStatus == RequestStatus.success,
    );
    final ids = state.drafts.map((item) => item.id).toList();
    // Vừa sửa trước
    expect(ids.indexOf(second.id!), lessThan(ids.indexOf(first.id!)));

    bloc.add(DraftOpened(first.id!));
    state = await _until(
      bloc,
      (s) => s.openDraftStatus == RequestStatus.success,
    );
    expect(state.draft.id, first.id);
    expect(state.draft.title, 'Nháp một');
    expect(state.draft.categoryId, 'phones');
    expect(state.draft.status, ListingStatus.draft);
    expect(state.hasUnsavedChanges, isFalse);

    bloc.add(DraftDeleted(first.id!));
    state = await _until(
      bloc,
      (s) =>
          s.drafts.every((item) => item.id != first.id) && s.draft.id == null,
    );
    // Xóa đúng tin đang soạn thì form trở lại tin mới
    expect(state.draft.title, isEmpty);
    expect(
      (await repository.mine(status: 'DRAFT')).items.map((item) => item.id),
      isNot(contains(first.id)),
    );
    await repository.deleteDraft(second.id!);
    await bloc.close();
  });

  test('opening a listing that is no longer a draft fails', () async {
    final repository = MockListingsRepository(latency: Duration.zero);
    final published = await repository.publish(
      const ListingDraft(title: 'Đã đăng'),
      null,
    );
    final bloc = _bloc(repository)..add(DraftOpened(published.id!));
    final state = await _until(
      bloc,
      (s) => s.openDraftStatus == RequestStatus.failure,
    );
    expect(state.draft.id, isNull);
    await bloc.close();
  });

  test(
    'draft limit: 3 drafts for a personal account, 4th is blocked',
    () async {
      final repository = MockListingsRepository(latency: Duration.zero);
      final ids = <String>[];
      for (var i = 0; i < 3; i++) {
        ids.add(
          (await repository.saveDraft(
            ListingDraft(title: 'Nháp $i'),
            null,
          )).id!,
        );
      }
      expect(
        await repository.draftQuota(),
        const DraftQuota(used: 3, limit: 3),
      );
      await expectLater(
        repository.saveDraft(const ListingDraft(title: 'Nháp thừa'), null),
        throwsA(
          isA<ListingSaveException>().having(
            (error) => error.isDraftLimitReached,
            'isDraftLimitReached',
            isTrue,
          ),
        ),
      );
      // Sửa nháp đã có vẫn lưu được
      await repository.saveDraft(
        (await repository.getDraft(ids.first)).copyWith(title: 'Nháp 0 sửa'),
        null,
      );

      final bloc = _bloc(repository)..add(const DraftsRequested());
      await _until(bloc, (s) => s.draftQuota?.isFull ?? false);
      bloc.add(const TitleChanged('Tin mới'));
      await _until(bloc, (s) => s.draft.title == 'Tin mới');
      // Đủ nháp: chặn ngay, không gọi API, view được báo
      expect(await bloc.saveDraftAndWait(), isFalse);
      expect(bloc.state.draftLimitHits, 1);
      expect((await repository.draftQuota()).used, 3);

      // Xóa một nháp thì lưu được
      bloc.add(DraftDeleted(ids.last));
      await _until(bloc, (s) => s.draftQuota?.used == 2);
      expect(await bloc.saveDraftAndWait(), isTrue);
      expect((await repository.draftQuota()).used, 3);
      for (final item in (await repository.mine(status: 'DRAFT')).items) {
        await repository.deleteDraft(item.id);
      }
      await bloc.close();
    },
  );

  test(
    'upload fails mid-save: retry updates the same draft, no duplicate',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
      final calls = <String>[];
      var uploads = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add('${request.method} ${request.path}');
            Map<String, dynamic> data = {
              'status': 'DRAFT',
              'id': 'd1',
              'images': [],
            };
            if (request.method == 'POST' &&
                request.path == '/listings/d1/images') {
              uploads++;
              if (uploads == 1) {
                return handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.receiveTimeout,
                  ),
                );
              }
              data = {'url': '/api/v1/listings/media/a.png'};
            }
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {'data': data},
              ),
            );
          },
        ),
      );
      final png = Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==',
        ),
      );
      final bloc = _bloc(
        ApiListingsRepository(dio: dio, readImage: (_) async => png),
      );
      bloc
        ..add(const TitleChanged('Máy ảnh'))
        ..add(const PhotosAdded(['/tmp/a.png']));
      await _until(bloc, (s) => s.draft.images.isNotEmpty);

      expect(await bloc.saveDraftAndWait(), isFalse);
      final failed = bloc.state;
      expect(failed.draft.id, 'd1');
      expect(failed.draft.images, ['/tmp/a.png']);
      expect(
        (failed.saveError! as ListingSaveException).isNetworkError,
        isTrue,
      );

      expect(await bloc.saveDraftAndWait(), isTrue);
      expect(
        calls.where((call) => call == 'POST /listings/drafts'),
        hasLength(1),
      );
      expect(calls, contains('PUT /listings/drafts/d1'));
      expect(
        bloc.state.draft.images.single,
        'http://localhost:3000/api/v1/listings/media/a.png',
      );
      await bloc.close();
    },
  );
  test(
    'a list fetched before a delete does not bring the draft back',
    () async {
      final repository = MockListingsRepository(latency: Duration.zero);
      final draft = await repository.saveDraft(
        const ListingDraft(title: 'Sẽ xóa'),
        null,
      );
      final keep = await repository.saveDraft(
        const ListingDraft(title: 'Giữ lại'),
        null,
      );
      final bloc = _bloc(repository)..add(const DraftsRequested());
      await _until(bloc, (s) => s.draftsStatus == RequestStatus.success);

      // Danh sách đang tải lại (VD vừa lưu nháp) thì người dùng bấm xóa
      bloc
        ..add(const DraftsRequested())
        ..add(DraftDeleted(draft.id!))
        ..add(DraftDeleted(draft.id!));
      await _until(bloc, (s) => s.draftsStatus == RequestStatus.loading);
      final state = await _until(
        bloc,
        (s) => s.draftsStatus == RequestStatus.success,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(state.drafts.map((item) => item.id), [keep.id]);
      expect(bloc.state.drafts.map((item) => item.id), [keep.id]);
      expect(bloc.state.draftDeleteFailures, 0);
      expect(bloc.state.draftQuota?.used, 1);
      await bloc.close();
    },
  );

  test('photos no longer on the device are dropped with a clear error', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
    final calls = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add('${request.method} ${request.path}');
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {
                'data': {'status': 'DRAFT', 'id': 'd1', 'images': []},
              },
            ),
          );
        },
      ),
    );
    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==',
      ),
    );
    final bloc = _bloc(
      ApiListingsRepository(
        dio: dio,
        readImage: (path) async => path.contains('gone')
            ? throw const FileSystemException('Cannot open file')
            : png,
      ),
    );
    bloc
      ..add(const TitleChanged('Máy ảnh'))
      ..add(const PhotosAdded(['/cache/a.png', '/cache/gone.jpg']));
    await _until(bloc, (s) => s.draft.images.length == 2);

    expect(await bloc.saveDraftAndWait(), isFalse);
    final error = bloc.state.saveError! as ListingSaveException;
    expect(error.imageProblem, ListingImageProblem.missing);
    expect(error.imagePaths, ['/cache/gone.jpg']);
    // Chưa đổi ảnh trên máy chủ; form giữ nội dung, chỉ bỏ ảnh đã mất
    expect(calls, ['POST /listings/drafts']);
    expect(bloc.state.draft.title, 'Máy ảnh');
    expect(bloc.state.draft.images, ['/cache/a.png']);
    await bloc.close();
  });

  test('deleting a draft reports its title', () async {
    final repository = MockListingsRepository(latency: Duration.zero);
    final draft = await repository.saveDraft(
      const ListingDraft(title: 'Bàn học'),
      null,
    );
    final bloc = _bloc(repository)..add(const DraftsRequested());
    await _until(bloc, (s) => s.draftsStatus == RequestStatus.success);
    bloc.add(DraftDeleted(draft.id!));
    final state = await _until(bloc, (s) => s.draftDeleteSuccesses == 1);
    expect(state.lastDeletedDraftTitle, 'Bàn học');
    await bloc.close();
  });

  test('deleting a draft already gone on the server counts as done', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: request, statusCode: 404),
          ),
        ),
      ),
    );
    await ApiListingsRepository(dio: dio).deleteDraft('gone');
  });
}
