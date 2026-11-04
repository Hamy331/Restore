class FeedUser {
  const FeedUser({required this.id, required this.name, this.avatarUrl});
  FeedUser.fromJson(Map<String, dynamic> j)
    : id = '${j['id'] ?? ''}',
      name = j['fullName'] as String? ?? '',
      avatarUrl = j['avatarUrl'] as String?;
  final String id, name;
  final String? avatarUrl;
}

class FeedComment {
  const FeedComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.liked = false,
  });
  FeedComment.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      author = FeedUser.fromJson(Map<String, dynamic>.from(j['author'])),
      text = j['text'],
      createdAt = DateTime.parse('${j['createdAt']}'),
      likes = (j['likeCount'] as num?)?.toInt() ?? 0,
      liked = j['likedByMe'] == true;
  final String id, text;
  final FeedUser author;
  final DateTime createdAt;
  final int likes;
  final bool liked;

  FeedComment copyWith({int? likes, bool? liked}) => FeedComment(
    id: id,
    author: author,
    text: text,
    createdAt: createdAt,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
  );
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.image,
    this.isMine = false,
    this.likes = 0,
    this.liked = false,
    this.following = false,
    this.commentCount = 0,
  });
  FeedPost.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      author = FeedUser.fromJson(Map<String, dynamic>.from(j['author'])),
      text = j['text'] ?? '',
      createdAt = DateTime.parse('${j['createdAt']}'),
      image = j['imageUrl'],
      likes = (j['likeCount'] as num?)?.toInt() ?? 0,
      liked = j['likedByMe'] == true,
      isMine = j['isMine'] == true,
      following = j['isFollowingAuthor'] == true,
      commentCount = (j['commentCount'] as num?)?.toInt() ?? 0;
  final String id, text;
  final FeedUser author;
  final DateTime createdAt;
  final String? image;
  final bool isMine, liked, following;
  final int likes, commentCount;

  String get authorId => author.id;

  FeedPost copyWith({
    int? likes,
    bool? liked,
    bool? following,
    int? commentCount,
  }) => FeedPost(
    id: id,
    author: author,
    text: text,
    createdAt: createdAt,
    image: image,
    isMine: isMine,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
    following: following ?? this.following,
    commentCount: commentCount ?? this.commentCount,
  );
}

/// Một trang kết quả phân trang bằng con trỏ.
class FeedPage<T> {
  const FeedPage(this.items, this.nextCursor);
  final List<T> items;
  final String? nextCursor;
}
