import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/ai/bloc/ai_assistant_cubit.dart';
import 'package:restore/modules/ai/models/assistant_reply.dart';
import 'package:restore/modules/ai/repositories/assistant_repository.dart';
import 'package:restore/modules/ai/views/ai_assistant_view.dart';

class FakeAssistantRepository extends AssistantRepository {
  FakeAssistantRepository() : super(dio: Dio());
  final calls = <List<String>>[];
  Completer<AssistantReply>? pending;
  bool fail = false;
  @override
  Future<({List<AssistantTurn> turns, Map<String, String> confirmed})> history(
    String id,
  ) async {
    return (
      turns: [
        const AssistantTurn(
          id: 'previous',
          input: 'Tìm bàn',
          reply: AssistantReply(text: 'Có một tin phù hợp.'),
        ),
      ],
      confirmed: {'action': 'saved'},
    );
  }

  void Function(Map<String, dynamic>)? events;
  @override
  Future<AssistantReply> send(
    String conversationId,
    String requestId,
    String message, {
    void Function(Map<String, dynamic>)? onEvent,
    CancelToken? cancelToken,
  }) async {
    events = onEvent;
    calls.add([conversationId, requestId, message]);
    if (fail) throw StateError('offline');
    return pending?.future ??
        Future.value(const AssistantReply(text: 'Kết quả từ API'));
  }

  @override
  Future<void> remove(String conversationId) async {}
}

void main() {
  test('suggestions are optional in old API replies', () {
    expect(
      AssistantReply.fromJson({
        'text': 'OK',
        'listings': [],
        'sources': [],
      }).suggestions,
      isEmpty,
    );
    expect(
      AssistantReply.fromJson({
        'text': 'Chọn',
        'listings': [],
        'sources': [],
        'suggestions': ['Tìm sản phẩm'],
      }).suggestions,
      ['Tìm sản phẩm'],
    );
  });

  testWidgets(
    'latest quick choices submit through the normal conversation and disable while busy',
    (tester) async {
      final repository = FakeAssistantRepository();
      final cubit = AiAssistantCubit(repository: repository);
      repository.pending = Completer<AssistantReply>();
      final send = cubit.submitted('asdfgh');
      repository.pending!.complete(
        const AssistantReply(
          text: 'Bạn chọn nhé',
          suggestions: ['Tìm sản phẩm', 'Bắt đầu lại'],
        ),
      );
      await send;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: cubit,
            child: const AiAssistantView(),
          ),
        ),
      );
      expect(find.byType(ActionChip), findsNWidgets(2));
      repository.pending = Completer<AssistantReply>();
      await tester.tap(find.widgetWithText(ActionChip, 'Tìm sản phẩm'));
      await tester.pump();
      expect(repository.calls.last.last, 'Tìm sản phẩm');
      expect(repository.calls.last.first, repository.calls.first.first);
      expect(find.byType(ActionChip), findsNothing);
      repository.pending!.complete(
        const AssistantReply(text: 'Bạn muốn tìm gì?'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );

  test(
    'opening history restores turns, draft confirmations and follow-up destination',
    () async {
      final repository = FakeAssistantRepository();
      final cubit = AiAssistantCubit(repository: repository);
      await cubit.openConversation('older-chat');
      expect(cubit.state.turns.single.input, 'Tìm bàn');
      expect(cubit.state.confirmed['action'], 'saved');
      await cubit.submitted('Giá bao nhiêu?');
      expect(repository.calls.single.first, 'older-chat');
      await cubit.close();
    },
  );
  test(
    'stream progress is provisional and clears on failure before retry',
    () async {
      final repository = FakeAssistantRepository()
        ..pending = Completer<AssistantReply>();
      final cubit = AiAssistantCubit(repository: repository);
      final send = cubit.submitted('Tìm sản phẩm');
      repository.events!({'type': 'status', 'stage': 'searching_listings'});
      expect(cubit.state.stage, 'searching_listings');
      repository.events!({'type': 'delta', 'text': 'Đang trả lời'});
      expect(cubit.state.partialText, 'Đang trả lời');
      expect(cubit.state.turns.last.reply, isNull);
      repository.pending!.completeError(
        const AssistantStreamException('Bị ngắt'),
      );
      await send;
      expect(cubit.state.partialText, isEmpty);
      expect(cubit.state.error, 'Bị ngắt');
      expect(cubit.state.canRetry, isTrue);
      await cubit.close();
    },
  );
  test(
    'failed send retries same request id and follow-up keeps conversation',
    () async {
      final repository = FakeAssistantRepository()..fail = true;
      final cubit = AiAssistantCubit(repository: repository);
      await cubit.submitted('Samsung dưới 5 triệu');
      expect(cubit.state.canRetry, isTrue);
      repository.fail = false;
      await cubit.retry();
      expect(repository.calls[0], repository.calls[1]);
      expect(cubit.state.turns.single.reply!.text, 'Kết quả từ API');
      await cubit.submitted('rẻ hơn chút');
      expect(repository.calls[2][0], repository.calls[0][0]);
      expect(repository.calls[2][1], isNot(repository.calls[0][1]));
      await cubit.close();
    },
  );

  test(
    'in-flight sends are not duplicated and completion after close is safe',
    () async {
      final repository = FakeAssistantRepository()
        ..pending = Completer<AssistantReply>();
      final cubit = AiAssistantCubit(repository: repository);
      final first = cubit.submitted('Tìm laptop');
      await cubit.submitted('Tìm laptop');
      expect(repository.calls.length, 1);
      await cubit.close();
      repository.pending!.complete(const AssistantReply(text: 'Xong'));
      await first;
    },
  );

  test('new chat clears local history', () async {
    final repository = FakeAssistantRepository();
    final cubit = AiAssistantCubit(repository: repository);
    await cubit.submitted('Soạn nháp');
    final old = repository.calls.first.first;
    await cubit.startOver();
    expect(cubit.state.turns, isEmpty);
    await cubit.submitted('Xin chào');
    expect(repository.calls.last.first, isNot(old));
    await cubit.close();
  });

  testWidgets('assistant renders sources and hides legacy draft actions', (
    tester,
  ) async {
    final repository = FakeAssistantRepository()
      ..pending = Completer<AssistantReply>();
    final cubit = AiAssistantCubit(repository: repository);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: cubit, child: const AiAssistantView()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Soạn tin điện thoại');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pending!.complete(
      const AssistantReply(
        text: 'Đây là bản nháp, chưa lưu.',
        sources: [
          {'id': 'policy', 'title': 'Hạn mức', 'text': 'Nội dung thật'},
        ],
        draft: {
          'id': 'action',
          'title': 'Điện thoại cũ',
          'description': 'Mô tả điện thoại',
          'price': '2000000',
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đây là bản nháp, chưa lưu.'), findsOneWidget);
    expect(find.text('Nguồn: Hạn mức'), findsOneWidget);
    expect(find.text('Xác nhận lưu nháp'), findsNothing);
    expect(find.text('Xem lại bản nháp'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
