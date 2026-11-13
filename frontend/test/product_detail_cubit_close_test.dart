import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/listings/bloc/product_detail/product_detail_cubit.dart';
import 'package:restore/modules/listings/models/product_detail.dart';
import 'package:restore/modules/listings/repositories/product_detail_repository.dart';

/// Chi tiết tin chỉ trả về khi test cho phép
class _SlowRepository implements ProductDetailRepository {
  final detail = Completer<ProductDetail>();

  @override
  Future<ProductDetail> getDetail(String listingId) => detail.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('leaving the page before the listing loads does not throw', () async {
    final repository = _SlowRepository();
    final cubit = ProductDetailCubit(listingId: 'l1', repository: repository);
    final loading = cubit.load();
    await cubit.close();
    repository.detail.completeError(Exception('network'));
    await expectLater(loading, completes);
  });
}
