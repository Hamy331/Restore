import 'package:equatable/equatable.dart';

/// Một lần tìm kiếm đã lưu của người dùng (`GET /search/history`)
class SearchHistoryEntry extends Equatable {
  final String id;
  final String keyword;
  final DateTime? searchedAt;

  const SearchHistoryEntry({
    required this.id,
    required this.keyword,
    this.searchedAt,
  });

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SearchHistoryEntry(
        id: '${json['id']}',
        keyword: json['keyword'] as String,
        searchedAt: DateTime.tryParse('${json['searchedAt']}'),
      );

  @override
  List<Object?> get props => [id, keyword, searchedAt];
}
