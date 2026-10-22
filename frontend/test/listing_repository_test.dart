import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/data/models/enums/listing_status.dart';
import 'package:restore/modules/listings/models/listing_draft.dart';
import 'package:restore/modules/listings/repositories/listings_repository.dart';
import 'package:restore/shared/models/paged_result.dart';

void main() {
  test('owner draft resumes unset condition/price and server media origin', () {
    final item = ListingModel.fromJson({
      'id': 'draft',
      'status': 'DRAFT',
      'price': '0',
      'condition': null,
      'images': ['/api/v1/listings/media/test.png'],
      'attributes': {'year': 2026},
    }, apiBaseUrl: 'http://localhost:3000/api/v1');
    final draft = ListingDraft.fromListing(item);
    expect(draft.price, isNull);
    expect(draft.condition, isNull);
    expect(draft.attributes['year'], '2026');
    expect(
      draft.images.single,
      'http://localhost:3000/api/v1/listings/media/test.png',
    );
    expect(draft.toPayload(category: null).containsKey('images'), false);
    expect(
      PagedResult.fromJson(
        {
          'data': [],
          'pagination': {'totalPages': 2},
        },
        ListingModel.fromJson,
        page: 1,
        pageSize: 20,
      ).hasMore,
      true,
    );
  });
  test(
    'partial upload keeps ID and uploaded URL for retry without duplicate upload',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
      var uploads = 0;
      var creates = 0;
      var shouldFail = true;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            Object body = {'success': true};
            if (request.path == '/listings/drafts' ||
                request.path == '/listings/drafts/saved') {
              if (request.method == 'POST') creates++;
              body = {
                'data': {'id': 'saved', 'status': 'DRAFT', 'images': []},
              };
            } else if (request.method == 'POST' &&
                request.path.endsWith('/images')) {
              uploads++;
              if (uploads == 2 && shouldFail) {
                handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              body = {
                'data': {'url': '/api/v1/listings/media/$uploads.png'},
              };
            } else if (request.path.endsWith('/publish')) {
              body = {
                'data': {
                  'id': 'saved',
                  'status': 'PENDING',
                  'images': [
                    '/api/v1/listings/media/1.png',
                    '/api/v1/listings/media/3.png',
                  ],
                },
              };
            } else if (request.path.contains('/mine/')) {
              body = {
                'data': {'id': 'saved', 'status': 'DRAFT', 'images': []},
              };
            }
            handler.resolve(
              Response(requestOptions: request, data: body, statusCode: 200),
            );
          },
        ),
      );
      final repository = ApiListingsRepository(
        dio: dio,
        readImage: (_) =>
            Future.value(Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10])),
      );
      ListingDraft? partial;
      try {
        await repository.saveDraft(
          const ListingDraft(
            images: ['blob:http://localhost/a', 'blob:http://localhost/b'],
          ),
          null,
        );
        fail('Expected second upload to fail');
      } on ListingSaveException catch (error) {
        partial = error.draft;
      }
      expect(partial.id, 'saved');
      expect(
        partial.images.first,
        'http://localhost:3000/api/v1/listings/media/1.png',
      );
      expect(partial.images.last, 'blob:http://localhost/b');
      shouldFail = false;
      final published = await repository.publish(partial, null);
      expect(creates, 1);
      expect(uploads, 3);
      expect(published.status, ListingStatus.pending);
    },
  );
}
