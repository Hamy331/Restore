import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/admin/presentation/admin_boost.dart';
import 'package:restore/modules/admin/presentation/admin_commerce.dart';
import 'package:restore/modules/admin/presentation/admin_preview_data.dart';
import 'package:restore/modules/stores/data/store_repository.dart';

void main() {
  testWidgets('store approval calls API only after confirmation', (
    tester,
  ) async {
    final decisions = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          if (request.method == 'POST') decisions.add(request);
          final orders =
              request.path == '/stores/admin/orders' && decisions.isEmpty
              ? [
                  {
                    'id': 'order-1',
                    'amount': '99000',
                    'user': {
                      'fullName': 'Test User',
                      'email': 'test@example.com',
                    },
                    'package': {'name': 'Basic'},
                    'category': {'name': 'Điện thoại'},
                  },
                ]
              : [];
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {'success': true, 'data': orders},
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminCommerceView(repository: StoreRepository(dio: dio)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận đã thanh toán'));
    await tester.pumpAndSettle();
    expect(decisions, isEmpty);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(decisions, isEmpty);
    await tester.tap(find.text('Xác nhận đã thanh toán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(decisions.single.path, '/stores/admin/orders/order-1/confirm');
    expect(find.text('Không có đơn đang chờ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boost form rejects nonpositive prices', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AdminPreviewCubit(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(child: AdminBoostView()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gói Boost'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm gói Boost'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên gói'),
      'Gói thử',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Giá (VND)'),
      '-1',
    );
    await tester.tap(find.text('Lưu gói mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập số nguyên lớn hơn 0.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
