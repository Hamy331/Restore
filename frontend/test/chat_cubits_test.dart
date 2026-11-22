import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/chat/views/conversation/chat_info_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/chat/bloc/conversation/conversation_cubit.dart';
import 'package:restore/modules/chat/bloc/conversations/conversations_cubit.dart';
import 'package:restore/modules/chat/models/chat_models.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/chat/views/conversation/live_chat_conversation_view.dart';

void main() {
  testWidgets(
    'chat information lists all discussed products and persists block and hide choices',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = ApiClient(), writes = <Object?>[], reports = <dynamic>[];
      final fixture = InterceptorsWrapper(
        onRequest: (req, handler) {
          if (req.method == 'PATCH') writes.add(req.data);
          if (req.path == '/content/reports') reports.add(req.data);
          final data = req.path.endsWith('/products')
              ? [
                  for (final name in ['Phone', 'TV', 'Watch'])
                    {
                      'contextId': 'context-$name',
                      'id': name,
                      'title': name,
                      'price': 100,
                    },
                ]
              : req.path.endsWith('/messages')
              ? {'items': []}
              : req.data;
          handler.resolve(
            Response(
              requestOptions: req,
              statusCode: 200,
              data: {'data': data},
            ),
          );
        },
      );
      client.dio.interceptors.insert(0, fixture);
      addTearDown(() => client.dio.interceptors.remove(fixture));
      final router = GoRouter(
        initialLocation: '/conversation',
        routes: [
          GoRoute(
            path: '/conversation',
            builder: (_, s) => LiveChatConversationView(
              conversationId: 'c1',
              repository: _FakeChatRepository(),
            ),
          ),
          GoRoute(
            path: '/messages',
            builder: (_, s) => const Scaffold(body: Text('Inbox')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thông tin hội thoại'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatInfoView), findsOneWidget);
      expect(
        find.text('Chưa có hình hoặc video trong hội thoại.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tin đang trao đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Watch'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Báo xấu'), 160);
      await tester.tap(find.text('Báo xấu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Spam trong hội thoại');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(reports.single['targetId'], 'u1');
      expect(reports.single['targetType'], 'USER');
      await tester.scrollUntilVisible(find.text('Chặn người dùng'), 160);
      await tester.tap(find.text('Chặn người dùng'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Chặn người dùng'));
      await tester.pumpAndSettle();
      expect(writes, [
        {'blocked': true},
      ]);
      expect(find.text('Bỏ chặn người dùng'), findsOneWidget);
      await tester.tap(find.text('Bỏ chặn người dùng'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Bỏ chặn người dùng'));
      await tester.pumpAndSettle();
      expect(writes.last, {'blocked': false});
      await tester.scrollUntilVisible(find.text('Ẩn hội thoại'), 160);
      await tester.tap(find.text('Ẩn hội thoại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(writes.length, 2);
      await tester.tap(find.text('Ẩn hội thoại'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Ẩn hội thoại'));
      await tester.pumpAndSettle();
      expect(writes.last, {'hidden': true});
      expect(find.text('Inbox'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'listing chat shows current product and the original inquiry price to both participants',
    (tester) async {
      for (final seller in [false, true]) {
        final repository = _FakeChatRepository();
        final product = {
          'id': 'p1',
          'title': 'iPhone 8 Plus',
          'price': '2000000',
        };
        repository.trade = ChatTrade.fromJson({
          'title': product['title'],
          'stage': 'closed',
          'seller': seller,
          'product': product,
          'canOffer': !seller,
        });
        repository.messages.add(
          ChatMessage.fromJson({
            'id': 'm1',
            'senderId': seller ? 'buyer' : 'me',
            'text': 'Còn hàng không?',
            'createdAt': '2026-11-20T08:00:00Z',
            'listingPreview': {...product, 'price': '2500000'},
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: LiveChatConversationView(
              conversationId: 'c1',
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('20/11/2026'), findsOneWidget);
        expect(find.text('iPhone 8 Plus'), findsNWidgets(2));
        expect(find.textContaining('2.000.000'), findsOneWidget);
        expect(find.textContaining('2.500.000'), findsOneWidget);
        expect(find.text('Còn hàng không?'), findsOneWidget);
        expect(
          find.byType(FilledButton),
          seller ? findsNothing : findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  test('conversations reload when a realtime event arrives', () async {
    final repository = _FakeChatRepository();
    final cubit = ConversationsCubit(repository)..start();
    await pumpEventQueue();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.conversations.single.id, 'c1');
    final loads = repository.listCalls;
    repository.events$.add('message');
    await pumpEventQueue();
    expect(repository.listCalls, loads + 1);
    await cubit.close();
    expect(repository.events$.hasListener, isFalse);
  });

  test(
    'conversation load failure is reported, silent refresh is not',
    () async {
      final repository = _FakeChatRepository()..failMessages = true;
      final cubit = ConversationCubit(repository, 'c1');
      await cubit.load(silent: true);
      expect(cubit.state.failed, isFalse);
      await cubit.load();
      expect(cubit.state.failed, isTrue);
      repository.failMessages = false;
      await cubit.load();
      expect(cubit.state.failed, isFalse);
      expect(cubit.state.selfId, 'me');
      expect(repository.reads, 1);
      await cubit.close();
    },
  );

  test('sending trims text and flags failures', () async {
    final repository = _FakeChatRepository();
    final cubit = ConversationCubit(repository, 'c1');
    await cubit.load();
    expect(await cubit.send('   '), isFalse);
    expect(await cubit.send(' Xin chào '), isTrue);
    expect(cubit.state.messages.last.text, 'Xin chào');
    expect(cubit.state.isMine(cubit.state.messages.last), isTrue);
    repository.failSend = true;
    expect(await cubit.send('Lỗi'), isFalse);
    expect(cubit.state.sendFailed, isTrue);
    expect(cubit.state.sending, isFalse);
    await cubit.close();
  });

  testWidgets('conversation view sends and clears the composer', (
    tester,
  ) async {
    final repository = _FakeChatRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: LiveChatConversationView(
          conversationId: 'c1',
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Minh Anh'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Còn hàng không?');
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pumpAndSettle();
    expect(find.text('Còn hàng không?'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    // Dừng hẹn giờ làm mới của cubit trước khi test kết thúc.
    await tester.pumpWidget(const SizedBox());
  });
}

class _FakeChatRepository implements ChatRepository {
  final events$ = StreamController<String>.broadcast();
  final _other = const ChatPerson(id: 'u1', fullName: 'Minh Anh');
  final List<ChatMessage> messages = [];
  ChatTrade? trade;
  bool failMessages = false, failSend = false;
  int listCalls = 0, reads = 0;

  ChatConversation get _conversation => ChatConversation(
    id: 'c1',
    otherUser: _other,
    unreadCount: 0,
    trade: trade,
  );

  @override
  Future<int> getUnreadCount() async => 0;
  @override
  Future<String> currentUserId() async => 'me';
  @override
  Future<String> startConversation(String recipientId) async => 'c1';
  @override
  Future<List<ChatConversation>> listConversations() async {
    listCalls++;
    return [_conversation];
  }

  @override
  Future<ChatConversation> getConversation(String id) async => _conversation;
  @override
  Future<List<ChatMessage>> getMessages(String id, {int? before}) async {
    if (failMessages) throw Exception('offline');
    return List.of(messages);
  }

  @override
  Future<ChatMessage> sendMessage(
    String id,
    String clientId,
    String text, {
    String? listingId,
    int? offerPrice,
  }) async {
    if (failSend) throw Exception('offline');
    final message = ChatMessage(
      id: clientId,
      senderId: 'me',
      text: text,
      createdAt: DateTime.now(),
    );
    messages.add(message);
    return message;
  }

  @override
  Future<void> markRead(String id, {int? through}) async => reads++;
  @override
  Stream<String> events() => events$.stream;
}
