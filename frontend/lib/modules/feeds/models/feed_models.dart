class FeedComment {
  FeedComment.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      authorId = j['author']['id'],
      author = j['author']['fullName'],
      avatarUrl = j['author']['avatarUrl'],
      text = j['text'],
      createdAt = DateTime.parse(j['createdAt']),
      likes = j['likeCount'],
      liked = j['likedByMe'];
  final String id, authorId, author, text;
  final String? avatarUrl;
  final DateTime createdAt;
  int likes;
  bool liked;
}

class FeedPost {
  FeedPost.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      authorId = j['author']['id'],
      author = j['author']['fullName'],
      avatarUrl = j['author']['avatarUrl'],
      text = j['text'],
      createdAt = DateTime.parse(j['createdAt']),
      image = j['imageUrl'],
      listingId = j['listing']?['id'],
      listingTitle = j['listing']?['title'],
      price = int.tryParse('${j['listing']?['price']}'),
      likes = j['likeCount'],
      liked = j['likedByMe'],
      isMine = j['isMine'],
      following = j['isFollowingAuthor'],
      commentCount = j['commentCount'];
  final String id, authorId, author, text;
  final DateTime createdAt;
  final String? avatarUrl, image, listingId, listingTitle;
  final int? price;
  final bool isMine;
  int likes, commentCount;
  bool liked, following;
  List<FeedComment> comments = [];
}
