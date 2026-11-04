import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/localized_text.dart';

/// Chủ đề gắn vào bài viết (Hỏi đáp, Khoe đồ, Cần mua...) để lọc Bảng tin.
class PostTopic extends Equatable {
  final String id;
  final LocalizedText name;

  const PostTopic({required this.id, required this.name});

  factory PostTopic.fromJson(Map<String, dynamic> json) => PostTopic(
    id: '${json['id']}',
    name: LocalizedText.fromJson(json['name']),
  );

  @override
  List<Object?> get props => [id, name];
}
