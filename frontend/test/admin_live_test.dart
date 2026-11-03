import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/modules/admin/data/admin_repository.dart';
import 'package:restore/modules/admin/presentation/admin_live_workspace.dart';
import 'package:restore/modules/stores/data/store_repository.dart';

void main() {
  testWidgets(
    'live workspace loads every section at mobile and desktop widths',
    (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            final Object data = switch (request.path) {
              '/admin/me' => {'fullName': 'Admin kiểm thử'},
              '/admin/dashboard' => {
                'pendingListings': 2,
                'openReports': 1,
                'logs': [],
              },
              '/admin/catalog' => {'categories': [], 'conditions': []},
              '/admin/store-packages' ||
              '/stores/admin/orders' ||
              '/promotions/admin/orders' ||
              '/promotions/packages' => [],
              _ => {'items': [], 'total': 0, 'page': 1},
            };
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
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [320.0, 1440.0]) {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AdminLiveWorkspace(
              key: ValueKey(width),
              repository: AdminRepository(dio: dio),
              commerceRepository: StoreRepository(dio: dio),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final title in [
          'Kiểm duyệt tin',
          'Báo cáo vi phạm',
          'Người dùng',
          'Danh mục & tình trạng',
          'Gói & đơn mua',
          'Bài viết',
          'Hỗ trợ người dùng',
          'Tri thức',
          'Nhật ký quản trị',
        ]) {
          if (width < 1000) {
            await tester.tap(find.byTooltip('Open navigation menu'));
            await tester.pumpAndSettle();
          }
          final menu = find.widgetWithText(ListTile, title);
          await tester.ensureVisible(menu);
          await tester.tap(menu);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$title at $width');
        }
      }
    },
  );

  testWidgets(
    'API decision errors stay visible and never report successful moderation',
    (tester) async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            if (request.method == 'POST') {
              handler.reject(
                DioException(
                  requestOptions: request,
                  response: Response(
                    requestOptions: request,
                    statusCode: 409,
                    data: {
                      'error': 'Dữ liệu đã đổi. Tải lại trước khi thao tác.',
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }
            final Object data = switch (request.path) {
              '/admin/me' => {'fullName': 'Admin'},
              '/admin/dashboard' => {'pendingListings': 1, 'logs': []},
              '/admin/listings' => {
                'items': [
                  {
                    'id': 'item',
                    'title': 'Bàn gỗ',
                    'status': 'PENDING',
                    'updatedAt': '2026-10-01T00:00:00Z',
                    'images': [],
                  },
                ],
                'total': 1,
                'page': 1,
              },
              _ => [],
            };
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
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminLiveWorkspace(repository: AdminRepository(dio: dio)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Kiểm duyệt tin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ra quyết định'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu vào hệ thống'));
      await tester.pumpAndSettle();
      expect(
        find.text('Dữ liệu đã đổi. Tải lại trước khi thao tác.'),
        findsOneWidget,
      );
      expect(
        requests
            .lastWhere((request) => request.method == 'POST')
            .data['updatedAt'],
        '2026-10-01T00:00:00Z',
      );
      expect(find.text('Lưu vào hệ thống'), findsOneWidget);
    },
  );
}
