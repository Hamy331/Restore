import '../../../core/network/media_url.dart';
import 'package:equatable/equatable.dart';

class FeedUser extends Equatable {
  const FeedUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.canPost = false,
    this.shopName,
    this.isAdmin = false,
  });
  FeedUser.fromJson(Map<String, dynamic> j)
    : id = '${j['id'] ?? ''}',
      name = j['fullName'] as String? ?? '',
      avatarUrl = resolveMediaUrl(j['avatarUrl'] as String?),
      canPost = j['canPost'] == true,
      shopName = (j['shop'] as Map?)?['name'] as String?,
      isAdmin = j['isAdmin'] == true;
  final String id, name;
  final String? avatarUrl;

  /// Tên cửa hàng khi tác giả là cửa hàng Đối tác (nhãn "Shop · tên" trên bài)
  final String? shopName;

  /// Tác giả là admin ReStore (nhãn "Admin ReStore" trên bài)
  final bool isAdmin;

  /// Cửa hàng Đối tác và admin mới đăng bài; người khác chỉ xem, thả tim, bình luận
  final bool canPost;

  @override
  List<Object?> get props => [id, name, avatarUrl, canPost, shopName, isAdmin];
}

class FeedComment extends Equatable {
  const FeedComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.image,
    this.parentId,
    this.likes = 0,
    this.liked = false,
  });
  FeedComment.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      author = FeedUser.fromJson(Map<String, dynamic>.from(j['author'])),
      text = j['text'] ?? '',
      image = resolveMediaUrl(j['imageUrl'] as String?),
      parentId = j['parentId'] as String?,
      createdAt = DateTime.parse('${j['createdAt']}'),
      likes = (j['likeCount'] as num?)?.toInt() ?? 0,
      liked = j['likedByMe'] == true;
  final String id, text;
  final String? image, parentId;
  final FeedUser author;
  final DateTime createdAt;
  final int likes;
  final bool liked;

  FeedComment copyWith({int? likes, bool? liked}) => FeedComment(
    id: id,
    author: author,
    text: text,
    createdAt: createdAt,
    image: image,
    parentId: parentId,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
  );

  @override
  List<Object?> get props => [
    id,
    author,
    text,
    createdAt,
    likes,
    liked,
    image,
    parentId,
  ];
}

class FeedPost extends Equatable {
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
      image = resolveMediaUrl(j['imageUrl'] as String?),
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

  @override
  List<Object?> get props => [
    id,
    author,
    text,
    createdAt,
    image,
    isMine,
    likes,
    liked,
    following,
    commentCount,
  ];
}

/// Một trang kết quả phân trang bằng con trỏ.
class FeedPage<T> {
  const FeedPage(this.items, this.nextCursor);
  final List<T> items;
  final String? nextCursor;
}
