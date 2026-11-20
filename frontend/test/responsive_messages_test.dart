import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/routes/app_router.dart';
import 'package:restore/data/models/user_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import 'package:restore/modules/chat/bloc/conversations/conversations_cubit.dart';
import 'package:restore/modules/chat/views/conversation/live_chat_conversation_mobile_view.dart';
import 'package:restore/modules/chat/views/messages/live_messages_mobile_view.dart';
import 'package:restore/modules/chat/widgets/desktop_conversation_list.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/repositories/location_repository.dart';
import 'package:restore/modules/shell/widgets/desktop_chat_controller.dart';
import 'package:restore/shared/widgets/desktop/desktop_header.dart';

void main() {
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  testWidgets('message routes keep the same UI and draft on resize', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 850);
    addTearDown(tester.view.reset);

    const user = UserModel(
      id: 'buyer',
      email: 'buyer@example.test',
      fullName: 'Test Buyer',
      username: 'buyer',
    );
    const conversation = {
      'id': 'chat-1',
      'otherUser': {'id': 'seller', 'fullName': 'Camera Shop'},
      'unreadCount': 0,
    };
    var inboxLoads = 0;
    final interceptor = InterceptorsWrapper(
      onRequest: (request, handler) {
        if (request.path == '/conversations') inboxLoads++;
        final response = switch (request.path) {
          '/conversations/events' => ResponseBody.fromString('', 200),
          '/conversations' => {
            'data': [conversation],
          },
          '/conversations/chat-1' => {'data': conversation},
          '/conversations/chat-1/messages' => {
            'data': {'items': []},
          },
          '/conversations/unread-count' => {
            'data': {'count': 0},
          },
          '/users/me' => {'data': user.toJson()},
          '/listings/search' => {'data': <Object>[]},
          _ => {'data': <String, Object>{}},
        };
        handler.resolve(
          Response(requestOptions: request, statusCode: 200, data: response),
        );
      },
    );
    final interceptors = ApiClient().dio.interceptors;
    interceptors.insert(0, interceptor);
    addTearDown(() => interceptors.remove(interceptor));

    final auth = AuthBloc(MockAuthRepository())..add(const LoggedIn(user));
    addTearDown(auth.close);
    await tester.pump();
    final router = createAppRouter(auth)..go('/messages');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider(
            create: (_) =>
                UserAreaCubit(locationRepository: MockLocationRepository())
                  ..selectNationwide(),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
          ),
        ),
      ),
    );
    await settleRoute(tester);

    final inbox = find.byType(LiveMessagesMobileView);
    final inboxElement = tester.element(inbox);
    final sharedInbox = inboxElement.read<ConversationsCubit>();
    final conversationView = find.byType(LiveChatConversationMobileView);
    expect(find.text('Camera Shop'), findsOneWidget);
    expect(find.text('Chọn một cuộc trò chuyện'), findsNothing);

    final loadsBeforeMobileChat = inboxLoads;
    await tester.tap(find.text('Camera Shop'));
    await tester.pumpAndSettle();
    expect(conversationView, findsOneWidget);
    expect(inbox, findsNothing);
    await tester.pump(const Duration(seconds: 13));
    expect(inboxLoads, loadsBeforeMobileChat);
    await tester.tap(find.byTooltip('Quay lại'));
    await settleRoute(tester);
    expect(tester.element(inbox), same(inboxElement));

    tester.view.physicalSize = const Size(1440, 900);
    await settleRoute(tester);
    expect(tester.element(inbox), same(inboxElement));
    expect(find.text('Camera Shop'), findsOneWidget);
    expect(find.text('Chọn một cuộc trò chuyện'), findsOneWidget);

    final initialInboxLoads = inboxLoads;
    await tester.tap(find.text('Camera Shop'));
    await tester.pumpAndSettle();
    expect(inbox, findsOneWidget);
    expect(tester.element(inbox), same(inboxElement));
    expect(inboxLoads, initialInboxLoads);
    expect(
      tester.getRect(inbox).right,
      lessThan(tester.getRect(conversationView).left),
    );
    final composer = find.descendant(
      of: conversationView,
      matching: find.byType(TextField),
    );
    await tester.enterText(composer, 'Bạn còn máy này không?');
    tester.view.physicalSize = const Size(390, 850);
    await settleRoute(tester);
    expect(inbox, findsNothing);
    expect(
      tester.widget<TextField>(composer).controller!.text,
      'Bạn còn máy này không?',
    );

    await tester.tap(find.byTooltip('Quay lại'));
    await settleRoute(tester);
    expect(inbox, findsOneWidget);

    tester.view.physicalSize = const Size(1440, 900);
    router.go('/search/results?q=camera');
    await settleRoute(tester);
    final headerContext = tester.element(find.byType(DesktopHeader));
    final dock = DesktopChatScope.maybeOf(headerContext)!;
    final loadsBeforeWaiting = inboxLoads;
    await tester.pump(const Duration(seconds: 13));
    expect(inboxLoads, loadsBeforeWaiting);

    dock.openConversation('chat-1');
    await settleRoute(tester);
    final dockList = find.byType(DesktopConversationList);
    expect(
      tester.element(dockList).read<ConversationsCubit>(),
      same(sharedInbox),
    );
    expect(find.text('Camera Shop'), findsWidgets);
    expect(inboxLoads, loadsBeforeWaiting);

    dock.close();
    await settleRoute(tester);
    await tester.pump(const Duration(seconds: 13));
    expect(inboxLoads, loadsBeforeWaiting);

    dock.openConversation('chat-1');
    await settleRoute(tester);
    await tester.tap(find.byTooltip('Mở trang Tin nhắn'));
    await tester.pumpAndSettle();
    final uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/messages');
    expect(uri.queryParameters['conversation'], 'chat-1');
    expect(inbox, findsOneWidget);
    expect(conversationView, findsOneWidget);
    expect(tester.element(inbox).read<ConversationsCubit>(), same(sharedInbox));
    expect(inboxLoads, loadsBeforeWaiting);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 13));
    expect(inboxLoads, loadsBeforeWaiting);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleRoute(tester);
    await tester.pump(const Duration(seconds: 13));
    await tester.pump();
    expect(inboxLoads, loadsBeforeWaiting + 1);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
