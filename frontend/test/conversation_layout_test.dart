import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/chat/bloc/conversation/conversation_cubit.dart';
import 'package:restore/modules/chat/models/chat_models.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/chat/views/conversation/live_chat_conversation_mobile_view.dart';
import 'package:restore/modules/chat/widgets/chat_product_preview.dart';

class _LayoutRepository extends MockChatRepository {
  _LayoutRepository(this.count);
  final int count;

  @override
  Future<ChatConversation> getConversation(String id) async =>
      const ChatConversation(
        id: 'chat',
        otherUser: ChatPerson(id: 'seller', fullName: 'Camera Shop'),
        unreadCount: 0,
        trade: ChatTrade(
          'Camera',
          'conversation',
          false,
          false,
          product: ChatProduct('camera', 'Test camera', 1000000, null),
        ),
      );

  @override
  Future<List<ChatMessage>> getMessages(
    String id, {
    int? before,
    int? after,
  }) async => List.generate(
    count,
    (index) => ChatMessage(
      id: 'message-$index',
      senderId: 'seller',
      text: 'Message $index',
      createdAt: DateTime(2026, 11, 19, 12, index),
    ),
  );
}

Future<void> _open(WidgetTester tester, int count, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 850);
  addTearDown(tester.view.reset);
  final cubit = ConversationCubit(_LayoutRepository(count), 'chat');
  addTearDown(cubit.close);
  await cubit.load();
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LiveChatConversationMobileView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 1100.0]) {
    testWidgets('short chat starts below the product at width $width', (
      tester,
    ) async {
      await _open(tester, 2, width);
      final productBottom = tester
          .getBottomLeft(find.byType(ChatProductPreview))
          .dy;
      final firstTop = tester.getTopLeft(find.text('Message 0')).dy;
      expect(firstTop, greaterThan(productBottom));
      expect(firstTop - productBottom, lessThan(100));
      expect(
        tester.getTopLeft(find.text('Message 1')).dy,
        greaterThan(firstTop),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'long chat opens at the latest message and scrolls to older ones',
    (tester) async {
      await _open(tester, 40, 390);
      expect(find.text('Message 39').hitTestable(), findsOneWidget);
      final list = tester.widget<ListView>(find.byType(ListView));
      final controller = list.controller!;
      expect(controller.position.maxScrollExtent, greaterThan(0));
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('Message 0').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
