import 'package:equatable/equatable.dart';

/// Người được gắn thẻ trong bài viết (người mình đang theo dõi)
class PostMention extends Equatable {
  final String userId;
  final String fullName;
  final String? avatarUrl;

  const PostMention({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
  });

  factory PostMention.fromJson(Map<String, dynamic> json) => PostMention(
    userId: '${json['id']}',
    fullName: '${json['fullName']}',
    avatarUrl: json['avatarUrl'] as String?,
  );

  @override
  List<Object?> get props => [userId, fullName, avatarUrl];
}
