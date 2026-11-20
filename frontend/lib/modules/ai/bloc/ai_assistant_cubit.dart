import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';
import '../models/assistant_reply.dart';
import '../repositories/assistant_repository.dart';

String _uuid() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class AiAssistantState {
  const AiAssistantState({
    this.turns = const [],
    this.busy = false,
    this.error,
    this.confirmed = const {},
    this.stage,
    this.partialText = '',
  });
  final List<AssistantTurn> turns;
  final bool busy;
  final String? error;
  final Map<String, String> confirmed;
  final String? stage;
  final String partialText;
  bool get canRetry => turns.isNotEmpty && turns.last.reply == null;
}

class AiAssistantCubit extends Cubit<AiAssistantState>
    with SafeEmit<AiAssistantState> {
  AiAssistantCubit({AssistantRepository? repository})
    : _repository = repository ?? AssistantRepository(),
      super(const AiAssistantState());
  final AssistantRepository _repository;
  String _conversationId = _uuid();
  CancelToken? _cancel;
  DateTime? startedAt = DateTime.now();
  int historyLoads = 0;

  Future<void> restoreLatest() async {
    _update(busy: true);
    try {
      final recent = await listRecent();
      if (isClosed) return;
      if (recent.isNotEmpty) {
        await _loadHistory(recent.first.id);
      } else {
        _update();
      }
    } catch (error) {
      _update(error: _message(error));
    }
  }

  void _update({
    List<AssistantTurn>? turns,
    bool busy = false,
    String? error,
    Map<String, String>? confirmed,
    String? stage,
    String partialText = '',
  }) {
    emit(
      AiAssistantState(
        turns: turns ?? state.turns,
        busy: busy,
        error: error,
        confirmed: confirmed ?? state.confirmed,
        stage: stage,
        partialText: partialText,
      ),
    );
  }

  Future<void> submitted(String value) async {
    final message = value.trim();
    if (state.busy ||
        state.canRetry ||
        message.isEmpty ||
        message.length > 2000) {
      return;
    }
    final turn = AssistantTurn(id: _uuid(), input: message);
    _update(turns: [...state.turns, turn], busy: true);
    await _send(turn);
  }

  Future<void> retry() async {
    if (state.busy || !state.canRetry) return;
    _update(busy: true);
    await _send(state.turns.last);
  }

  Future<void> _send(AssistantTurn turn) async {
    _cancel = CancelToken();
    try {
      final reply = await _repository.send(
        _conversationId,
        turn.id,
        turn.input,
        cancelToken: _cancel,
        onEvent: (event) {
          if (isClosed) return;
          switch (event['type']) {
            case 'status':
              _update(
                busy: true,
                stage: event['stage'] as String?,
                partialText: state.partialText,
              );
            case 'delta':
              final text = state.partialText + (event['text'] as String? ?? '');
              if (text.length > 8000) {
                _cancel?.cancel();
                return;
              }
              _update(busy: true, stage: state.stage, partialText: text);
            case 'reset':
              _update(busy: true, stage: state.stage);
          }
        },
      );
      _update(
        turns: [
          ...state.turns.take(state.turns.length - 1),
          AssistantTurn(id: turn.id, input: turn.input, reply: reply),
        ],
      );
    } catch (error) {
      _update(error: _message(error));
    } finally {
      _cancel = null;
    }
  }


  Future<List<({String id, String title})>> listRecent({String? after}) =>
      _repository.listRecent(after: after);

  Future<void> startOver() async {
    if (state.busy) return;
    _conversationId = _uuid();
    startedAt = DateTime.now();
    emit(const AiAssistantState());
  }

  Future<void> openConversation(String id) async {
    if (state.busy) return;
    _update(busy: true);
    try {
      await _loadHistory(id);
    } catch (error) {
      _update(error: _message(error));
    }
  }

  Future<void> _loadHistory(String id) async {
    final history = await _repository.history(id);
    if (isClosed) return;
    _conversationId = id;
    startedAt = null;
    historyLoads++;
    _update(turns: history.turns, confirmed: history.confirmed);
  }

  String _message(Object error) {
    if (error is AssistantStreamException) return error.message;
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['error'] is String) {
        return body['error'] as String;
      }
    }
    return 'Chưa thể kết nối với AI. Bạn có thể thử lại.';
  }

  @override
  Future<void> close() {
    _cancel?.cancel('Assistant closed');
    return super.close();
  }
}
