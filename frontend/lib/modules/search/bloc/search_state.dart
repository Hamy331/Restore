import 'package:equatable/equatable.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';

import '../models/search_history_entry.dart';

class SearchState extends Equatable {
  /// Nội dung đang gõ (đã bỏ khoảng trắng hai đầu)
  final String query;
  final List<String> trending;
  final List<SearchHistoryEntry> history;

  /// Gợi ý cho [suggestionsQuery], có thể trễ hơn [query] một nhịp gõ
  final List<String> suggestions;
  final String suggestionsQuery;

  const SearchState({
    this.query = '',
    this.trending = const [],
    this.history = const [],
    this.suggestions = const [],
    this.suggestionsQuery = '',
  });

  bool get isTyping => query.isNotEmpty;

  /// Lịch sử khớp nội dung đang gõ, hiện trước các gợi ý
  List<SearchHistoryEntry> get matchingHistory => [
    for (final entry in history)
      if (_matches(entry.keyword)) entry,
  ];

  /// Gợi ý chưa có trong lịch sử, để không hiện trùng hai lần
  List<String> get freshSuggestions {
    final used = {
      for (final entry in matchingHistory)
        VietnameseText.normalize(entry.keyword),
    };
    return [
      for (final keyword in suggestions)
        if (!used.contains(VietnameseText.normalize(keyword))) keyword,
    ];
  }

  bool _matches(String keyword) => VietnameseText.matches(keyword, query);

  SearchState copyWith({
    String? query,
    List<String>? trending,
    List<SearchHistoryEntry>? history,
    List<String>? suggestions,
    String? suggestionsQuery,
  }) => SearchState(
    query: query ?? this.query,
    trending: trending ?? this.trending,
    history: history ?? this.history,
    suggestions: suggestions ?? this.suggestions,
    suggestionsQuery: suggestionsQuery ?? this.suggestionsQuery,
  );

  @override
  List<Object?> get props => [
    query,
    trending,
    history,
    suggestions,
    suggestionsQuery,
  ];
}
