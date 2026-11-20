import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/models/product_detail.dart';
import 'package:restore/modules/listings/repositories/product_detail_repository.dart';
import 'package:restore/modules/listings/views/product_detail/widgets/product_detail_seller_card.dart';
import 'package:restore/modules/shell/widgets/desktop_chat_controller.dart';

void main() {
  for (final desktop in [true, false]) {
    testWidgets('seller card send opens the conversation on desktop=$desktop', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(desktop ? 1366 : 390, 900);
      addTearDown(tester.view.reset);

      final chat = DesktopChatController();
      addTearDown(chat.dispose);
      const detail = ProductDetail(
        listing: ListingModel(
          id: 'listing-1',
          ownerId: 'seller-1',
          title: 'Film camera',
          description: 'Sample description',
        ),
        seller: UserModel(
          id: 'seller-1',
          email: '',
          fullName: 'Camera Shop',
          username: 'camera-shop',
        ),
        areaLabel: '',
      );
      final requests = <RequestOptions>[];
      final interceptors = ApiClient().dio.interceptors;
      final fixture = InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final data = switch (request.path) {
            '/conversations' => {'id': 'conversation-1'},
            '/conversations/conversation-1/messages' => {
              'id': 'message-1',
              'senderId': 'buyer-1',
              'text': 'Is this available?',
              'createdAt': '2026-11-20T00:00:00Z',
            },
            _ => {'id': 'seller-1'},
          };
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {'data': data},
            ),
          );
        },
      );
      interceptors.insert(0, fixture);
      addTearDown(() => interceptors.remove(fixture));

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: ProductDetailSellerCard(
                detail: detail,
                signedIn: () => true,
              ),
            ),
          ),
          GoRoute(
            path: '/messages/:id',
            builder: (_, state) => Scaffold(
              body: Text('Conversation ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        DesktopChatScope(
          controller: chat,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Is this available?');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      final send = requests.singleWhere(
        (request) => request.path == '/conversations/conversation-1/messages',
      );
      expect(send.data['listingId'], 'listing-1');
      expect(chat.isOpen, desktop);
      expect(chat.conversationId, desktop ? 'conversation-1' : null);
      expect(
        find.byType(ProductDetailSellerCard),
        desktop ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Conversation conversation-1'),
        desktop ? findsNothing : findsOneWidget,
      );
    });
  }

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
