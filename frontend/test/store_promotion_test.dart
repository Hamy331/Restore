import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/stores/data/store_repository.dart';

void main() {
  test(
    'store and promotion purchases create pending orders; included redemption is separate',
    () async {
      final calls = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls.add(options.path);
            if (options.path == '/stores/orders') {
              expect(options.data, {
                'packageId': 'basic',
                'categoryId': 'phones',
              });
            }
            if (options.path == '/promotions/orders' ||
                options.path == '/promotions/redeem') {
              expect(options.data, {
                'listingId': 'listing-1',
                'packageId': 'bump-3',
              });
            }
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'data': {'id': 'pending-1', 'status': 'PENDING'},
                },
              ),
            );
          },
        ),
      );
      final repository = StoreRepository(dio: dio);
      expect(
        await repository.orderStorePackage(
          packageId: 'basic',
          categoryId: 'phones',
        ),
        'pending-1',
      );
      expect(
        await repository.orderPromotion(
          listingId: 'listing-1',
          packageId: 'bump-3',
        ),
        'pending-1',
      );
      await repository.redeem(listingId: 'listing-1', packageId: 'bump-3');
      expect(calls, [
        '/stores/orders',
        '/promotions/orders',
        '/promotions/redeem',
      ]);
    },
  );
}
