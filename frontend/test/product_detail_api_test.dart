import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/listings/repositories/product_detail_repository.dart';

void main() {
  test(
    'detail reads public owner metadata and refresh does not count a view',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {
                  'data': {
                    'id': 'listing-1',
                    'title': 'Bàn gỗ',
                    'price': '100000',
                    'status': 'AVAILABLE',
                    'images': ['/api/v1/listings/media/photo.png'],
                    'owner': {
                      'id': 'seller-1',
                      'fullName': 'Người bán',
                      'ratingAverage': 4.5,
                    },
                    'isOwner': true,
                    'isFavorite': true,
                    'sellerActiveListings': 3,
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiProductDetailRepository(dio: dio);
      final detail = await repository.getDetail('listing-1');
      expect(detail.seller.fullName, 'Người bán');
      expect(detail.seller.email, isEmpty);
      expect(detail.isOwner, isTrue);
      expect(detail.isFavorite, isTrue);
      expect(detail.sellerActiveListings, 3);
      expect(requests.last.queryParameters['countView'], 'true');
      await repository.getDetail('listing-1', countView: false);
      expect(requests.last.queryParameters['countView'], 'false');
      await repository.setFavorite('listing-1', true);
      expect(requests.last.method, 'PUT');
      await repository.setFavorite('listing-1', false);
      expect(requests.last.method, 'DELETE');
    },
  );
}
