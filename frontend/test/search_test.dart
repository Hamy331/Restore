import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/modules/search/bloc/search_cubit.dart';
import 'package:restore/modules/search/repositories/search_repository.dart';
import 'package:restore/shared/models/listing_filter.dart';

/// ApiClient trả [data] cho mọi request và ghi lại request cuối
(ApiClient, List<RequestOptions>) _fakeClient(Map<String, dynamic> data) {
  final client = ApiClient();
  final requests = <RequestOptions>[];
  client.dio.interceptors.insert(
    0,
    InterceptorsWrapper(
      onRequest: (request, handler) {
        requests.add(request);
        handler.resolve(
          Response(requestOptions: request, data: data, statusCode: 200),
        );
      },
    ),
  );
  return (client, requests);
}

void main() {
  test(
    'search sends filters in the shape GET /listings/search expects',
    () async {
      final (client, requests) = _fakeClient({
        'data': <Object>[],
        'meta': {'page': 2, 'limit': 10, 'hasMore': false},
      });
      final result = await ApiSearchRepository(apiClient: client).search(
        'ghế gỗ',
        const ListingFilter(
          sort: ListingSort.priceLow,
          dealTypes: {ListingDealType.buy, ListingDealType.exchange},
          conditions: {ListingCondition.newItem, ListingCondition.usedGood},
          minPrice: 100000,
        ),
        page: 2,
      );
      final request = requests.single;
      expect(request.path, '/listings/search');
      expect(request.queryParameters, {
        'q': 'ghế gỗ',
        'deal': 'buy,exchange',
        'sort': 'price_asc',
        'minPrice': 100000,
        'condition': 'NEW,USED_GOOD',
        'page': 2,
        'limit': SearchRepository.pageSize,
      });
      expect(result.hasMore, isFalse);
    },
  );

  test('history and suggestions parse the search API', () async {
    final (client, requests) = _fakeClient({
      'data': [
        {
          'id': 'h1',
          'keyword': 'Ghế gỗ',
          'searchedAt': '2026-11-16T10:00:00.000Z',
        },
      ],
    });
    final history = await ApiSearchRepository(apiClient: client).getHistory();
    expect(requests.single.path, '/search/history');
    expect(history.single.keyword, 'Ghế gỗ');
    expect(history.single.searchedAt, DateTime.utc(2026, 11, 16, 10));

    final (suggestClient, suggestRequests) = _fakeClient({
      'data': ['ghế gỗ', 'Ghế gỗ sồi Bắc Âu'],
    });
    final suggestions = await ApiSearchRepository(
      apiClient: suggestClient,
    ).getSuggestions('ghe');
    expect(suggestRequests.single.path, '/search/suggestions');
    expect(suggestRequests.single.queryParameters['q'], 'ghe');
    expect(suggestions, ['ghế gỗ', 'Ghế gỗ sồi Bắc Âu']);
  });

  test('guests see quick picks but no search history', () async {
    final repository = MockSearchRepository(latency: Duration.zero);
    final guest = SearchCubit(searchRepository: repository, showHistory: false);
    await guest.start();
    expect(guest.state.trending, isNotEmpty);
    expect(guest.state.history, isEmpty);
    await guest.close();

    final member = SearchCubit(searchRepository: repository);
    await member.start();
    expect(member.state.history, isNotEmpty);
    await member.close();
  });
}
