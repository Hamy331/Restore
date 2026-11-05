import 'package:equatable/equatable.dart';
import '../../models/feed_models.dart';

/// Lỗi phát sinh từ thao tác (like, follow, bình luận, xoá, báo cáo).
/// Lỗi tải lần đầu dùng [FeedsState.failed], lỗi tải thêm dùng
/// [FeedsState.loadMoreFailed], lỗi đăng bài do composer tự báo.
enum FeedError { action }

class FeedsState extends Equatable {
  const FeedsState({
    this.posts = const [],
    this.comments = const {},
    this.commentCursors = const {},
    this.pending = const {},
    this.onlyFollowing = false,
    this.loading = false,
    this.failed = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.me,
    this.error,
  });
  final List<FeedPost> posts;

  /// Bình luận đã tải và con trỏ trang tiếp theo, theo id bài viết.
  final Map<String, List<FeedComment>> comments;
  final Map<String, String?> commentCursors;

  /// Khoá các thao tác đang chạy, ví dụ `comments:<id>`, `follow:<id>`.
  final Set<String> pending;
  final bool onlyFollowing, loading, failed, loadingMore, loadMoreFailed;
  final FeedUser? me;
  final FeedError? error;

  Set<String> get following =>
      posts.where((p) => p.following).map((p) => p.authorId).toSet();

  bool isPending(String key) => pending.contains(key);

  bool hasMoreComments(String postId) => commentCursors[postId] != null;

  /// [error] không được giữ qua các lần emit để snackbar chỉ hiện một lần.
  FeedsState copyWith({
    List<FeedPost>? posts,
    Map<String, List<FeedComment>>? comments,
    Map<String, String?>? commentCursors,
    Set<String>? pending,
    bool? onlyFollowing,
    bool? loading,
    bool? failed,
    bool? loadingMore,
    bool? loadMoreFailed,
    FeedUser? me,
    FeedError? error,
  }) => FeedsState(
    posts: posts ?? this.posts,
    comments: comments ?? this.comments,
    commentCursors: commentCursors ?? this.commentCursors,
    pending: pending ?? this.pending,
    onlyFollowing: onlyFollowing ?? this.onlyFollowing,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    me: me ?? this.me,
    error: error,
  );

  @override
  List<Object?> get props => [
    posts,
    comments,
    commentCursors,
    pending,
    onlyFollowing,
    loading,
    failed,
    loadingMore,
    loadMoreFailed,
    me,
    error,
  ];
}
