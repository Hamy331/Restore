import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/listings/repositories/product_detail_repository.dart';

void main() {
  test(
    'product chat sends seller recipientId to the conversation API',
    () async {
      final client = ApiClient();
      final requests = <RequestOptions>[];
      final fixture = InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {
                'data': request.method == 'GET'
                    ? {
                        'id': 'listing-1',
                        'seller': {'id': 'seller-1'},
                      }
                    : {'id': 'conversation-1'},
              },
            ),
          );
        },
      );
      client.dio.interceptors.insert(0, fixture);
      addTearDown(() => client.dio.interceptors.remove(fixture));

      final id = await ApiProductDetailRepository(
        apiClient: client,
      ).openConversation('listing-1');

      expect(id, 'conversation-1');
      expect(requests.first.path, '/listings/listing-1');
      expect(requests.last.path, '/conversations');
      expect(requests.last.data, {
        'recipientId': 'seller-1',
        'listingId': 'listing-1',
      });
    },
  );
}
