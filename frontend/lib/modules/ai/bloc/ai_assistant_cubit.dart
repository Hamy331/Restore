import 'package:flutter_bloc/flutter_bloc.dart';

enum AiAssistantStatus { welcome, results, filtered, comparison, empty, error }

class AiAssistantState {
  const AiAssistantState({
    this.status = AiAssistantStatus.welcome,
    this.query = '',
    this.draft = '',
  });

  final AiAssistantStatus status;
  final String query;
  final String draft;

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    String? query,
    String? draft,
  }) => AiAssistantState(
    status: status ?? this.status,
    query: query ?? this.query,
    draft: draft ?? this.draft,
  );
}

class AiAssistantCubit extends Cubit<AiAssistantState> {
  AiAssistantCubit() : super(const AiAssistantState());

  void submitted(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    final normalized = query.toLowerCase();
    final status = normalized.contains('so sánh')
        ? AiAssistantStatus.comparison
        : state.status == AiAssistantStatus.results
        ? AiAssistantStatus.filtered
        : AiAssistantStatus.results;
    emit(state.copyWith(status: status, query: query, draft: ''));
  }

  void draftChanged(String value) => emit(state.copyWith(draft: value));
  void draftSubmitted() => submitted(state.draft);

  void statusSelected(AiAssistantStatus value) =>
      emit(state.copyWith(status: value));
}
