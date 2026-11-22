import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/theme.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/chat/bloc/conversations/conversations_cubit.dart';
import 'package:restore/modules/chat/models/chat_models.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/chat/views/messages/live_messages_mobile_view.dart';

class _SearchRepository extends MockChatRepository {
  bool fail = false;

  @override
  Future<List<ChatConversation>> listConversations() async {
    if (fail) throw StateError('offline');
    return [
      const ChatConversation(
        id: 'shop',
        otherUser: ChatPerson(id: 'seller', fullName: 'Camera Shop'),
        unreadCount: 2,
      ),
      ChatConversation(
        id: 'buyer',
        otherUser: const ChatPerson(id: 'buyer', fullName: 'Minh Anh'),
        unreadCount: 0,
        lastMessage: ChatMessage(
          id: 'message',
          senderId: 'buyer',
          text: 'Which lens is included?',
          createdAt: DateTime(2026),
        ),
      ),
    ];
  }
}

void main() {
  testWidgets('messages search filters, survives refresh and clears', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 850);
    addTearDown(tester.view.reset);
    final repository = _SearchRepository();
    final cubit = ConversationsCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    String? selected;
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LiveMessagesMobileView(onSelect: (id) => selected = id),
          ),
        ),
      ),
    );
    expect(find.text('Camera Shop'), findsOneWidget);
    expect(find.text('Minh Anh'), findsOneWidget);
    final field = find.byType(TextField);
    await tester.enterText(field, '  CAMERA ');
    await tester.pump();
    expect(find.text('Camera Shop'), findsOneWidget);
    expect(find.text('Minh Anh'), findsNothing);

    await cubit.load();
    await tester.pump();
    expect(cubit.state.searchQuery, '  CAMERA ');
    expect(find.text('Minh Anh'), findsNothing);
    repository.fail = true;
    await cubit.load();
    await tester.pump();
    expect(cubit.state.searchQuery, '  CAMERA ');
    expect(find.text('Camera Shop'), findsOneWidget);

    await tester.enterText(field, 'lens');
    await tester.pump();
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Camera Shop'), findsNothing);
    await tester.tap(find.text('Minh Anh'));
    expect(selected, 'buyer');

    await tester.enterText(field, 'no matching person');
    await tester.pump();
    expect(find.text('No matching conversations found.'), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pump();
    expect(cubit.state.searchQuery, isEmpty);
    expect(find.text('Camera Shop'), findsOneWidget);
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
