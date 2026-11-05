import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/modules/chat/bloc/conversation/conversation_cubit.dart';
import 'package:restore/modules/chat/bloc/conversations/conversations_cubit.dart';
import 'package:restore/modules/chat/models/chat_models.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/chat/views/conversation/live_chat_conversation_view.dart';

void main() {
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
  bool failMessages = false, failSend = false;
  int listCalls = 0, reads = 0;

  ChatConversation get _conversation =>
      ChatConversation(id: 'c1', otherUser: _other, unreadCount: 0);

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
  Future<List<ChatMessage>> getMessages(String id) async {
    if (failMessages) throw Exception('offline');
    return List.of(messages);
  }

  @override
  Future<ChatMessage> sendMessage(
    String id,
    String clientId,
    String text,
  ) async {
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
  Future<void> markRead(String id) async => reads++;
  @override
  Stream<String> events() => events$.stream;
}
