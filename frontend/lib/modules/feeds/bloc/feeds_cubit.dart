import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/feed_models.dart';
import '../repositories/feeds_repository.dart';
export '../models/feed_models.dart';

/// Lỗi phát sinh từ thao tác (like, follow, bình luận, xoá, báo cáo).
/// Lỗi tải lần đầu dùng [FeedsState.failed], lỗi tải thêm dùng
/// [FeedsState.loadMoreFailed], lỗi đăng bài do composer tự báo.
enum FeedError { action }

class FeedsState {
  const FeedsState({
    this.posts = const [],
    this.comments = const {},
    this.onlyFollowing = false,
    this.loading = false,
    this.failed = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.me,
    this.error,
  });
  final List<FeedPost> posts;

  /// Bình luận đã tải theo id bài viết.
  final Map<String, List<FeedComment>> comments;
  final bool onlyFollowing, loading, failed, loadingMore, loadMoreFailed;
  final FeedUser? me;
  final FeedError? error;
  Set<String> get following =>
      posts.where((p) => p.following).map((p) => p.authorId).toSet();

  /// [error] không được giữ qua các lần emit để snackbar chỉ hiện một lần.
  FeedsState copyWith({
    List<FeedPost>? posts,
    Map<String, List<FeedComment>>? comments,
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
    onlyFollowing: onlyFollowing ?? this.onlyFollowing,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    me: me ?? this.me,
    error: error,
  );
}

class FeedsCubit extends Cubit<FeedsState> {
  /// [authorId] khác null: danh sách bài của một người (trang hồ sơ), không
  /// có tab "Đang theo dõi".
  FeedsCubit({FeedsRepository? repository, this.authorId})
    : repository = repository ?? FeedsRepository(),
      super(const FeedsState());
  final FeedsRepository repository;
  final String? authorId;
  String? cursor;
  int generation = 0;
  final Set<String> pending = {};
  final Map<String, String?> commentCursors = {};

  void _emit(FeedsState next) {
    if (!isClosed) emit(next);
  }

  void _fail() => _emit(state.copyWith(error: FeedError.action));

  void _replace(FeedPost post) => _emit(
    state.copyWith(
      posts: [for (final p in state.posts) p.id == post.id ? post : p],
    ),
  );

  FeedPost? find(String id) {
    for (final p in state.posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> loadMe() async {
    if (state.me != null) return;
    try {
      final me = await repository.me();
      _emit(state.copyWith(me: me));
    } catch (_) {
      // Không có hồ sơ thì vẫn hiển thị avatar chữ "Bạn".
    }
  }

  /// Đổi tab thì xoá danh sách cũ để hiện spinner; làm mới cùng tab thì giữ
  /// danh sách đang có cho tới khi dữ liệu mới về.
  Future<void> load({bool? following}) async {
    final tab = following ?? state.onlyFollowing, version = ++generation;
    final keep = tab == state.onlyFollowing && !state.failed;
    _emit(
      FeedsState(
        posts: keep ? state.posts : const [],
        comments: state.comments,
        onlyFollowing: tab,
        loading: true,
        me: state.me,
      ),
    );
    try {
      final page = await repository.posts(following: tab, authorId: authorId);
      if (isClosed || version != generation) return;
      cursor = page.nextCursor;
      _emit(
        FeedsState(
          posts: page.items,
          comments: state.comments,
          onlyFollowing: tab,
          me: state.me,
        ),
      );
    } catch (e) {
      if (isClosed || version != generation) return;
      if (keep && state.posts.isNotEmpty) {
        _emit(state.copyWith(loading: false, error: FeedError.action));
      } else {
        _emit(FeedsState(onlyFollowing: tab, failed: true, me: state.me));
      }
    }
  }

  /// Lỗi thì dừng tự tải thêm khi cuộn; người dùng bấm "Thử lại" để gọi
  /// [loadMore] với `retry: true`.
  Future<void> loadMore({bool retry = false}) async {
    if (cursor == null || state.loadingMore || state.loading) return;
    if (state.loadMoreFailed && !retry) return;
    final version = generation;
    _emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await repository.posts(
        following: state.onlyFollowing,
        authorId: authorId,
        cursor: cursor,
      );
      if (isClosed || version != generation) return;
      cursor = page.nextCursor;
      final ids = state.posts.map((p) => p.id).toSet();
      _emit(
        state.copyWith(
          posts: [
            ...state.posts,
            ...page.items.where((p) => !ids.contains(p.id)),
          ],
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || version != generation) return;
      _emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  void select(bool following) {
    if (following == state.onlyFollowing && !state.failed) return;
    load(following: following);
  }

  Future<void> toggleFollow(String authorId) async {
    if (!pending.add('follow:$authorId')) return;
    try {
      final value = !state.following.contains(authorId);
      await repository.follow(authorId, value);
      _emit(
        state.copyWith(
          posts: [
            for (final p in state.posts)
              if (!(state.onlyFollowing && !value && p.authorId == authorId))
                p.authorId == authorId ? p.copyWith(following: value) : p,
          ],
        ),
      );
    } catch (e) {
      _fail();
    } finally {
      pending.remove('follow:$authorId');
    }
  }

  /// Cập nhật giao diện ngay, sau đó đồng bộ theo server; lỗi thì hoàn tác.
  Future<void> toggleLike(FeedPost post) async {
    if (!pending.add(post.id)) return;
    final current = find(post.id) ?? post;
    _replace(
      current.copyWith(
        liked: !current.liked,
        likes: current.likes + (current.liked ? -1 : 1),
      ),
    );
    try {
      final result = await repository.likePost(post.id, !current.liked);
      final latest = find(post.id);
      if (latest != null) {
        _replace(latest.copyWith(liked: result.liked, likes: result.likes));
      }
    } catch (e) {
      final latest = find(post.id);
      if (latest != null) {
        _replace(latest.copyWith(liked: current.liked, likes: current.likes));
      }
      _fail();
    } finally {
      pending.remove(post.id);
    }
  }

  void _replaceComment(String postId, FeedComment comment) => _emit(
    state.copyWith(
      comments: {
        ...state.comments,
        postId: [
          for (final c in state.comments[postId] ?? const <FeedComment>[])
            c.id == comment.id ? comment : c,
        ],
      },
    ),
  );

  Future<void> toggleCommentLike(String postId, FeedComment comment) async {
    if (!pending.add(comment.id)) return;
    _replaceComment(
      postId,
      comment.copyWith(
        liked: !comment.liked,
        likes: comment.likes + (comment.liked ? -1 : 1),
      ),
    );
    try {
      final result = await repository.likeComment(comment.id, !comment.liked);
      _replaceComment(
        postId,
        comment.copyWith(liked: result.liked, likes: result.likes),
      );
    } catch (e) {
      _replaceComment(postId, comment);
      _fail();
    } finally {
      pending.remove(comment.id);
    }
  }

  Future<void> loadComments(String id, {bool more = false}) async {
    if (!pending.add('comments:$id')) return;
    _emit(state.copyWith());
    try {
      final page = await repository.comments(
        id,
        cursor: more ? commentCursors[id] : null,
      );
      final merged = {
        for (final c in [if (more) ...?state.comments[id], ...page.items])
          c.id: c,
      };
      commentCursors[id] = page.nextCursor;
      pending.remove('comments:$id');
      _emit(
        state.copyWith(
          comments: {...state.comments, id: merged.values.toList()},
        ),
      );
    } catch (e) {
      pending.remove('comments:$id');
      _fail();
    }
  }

  Future<bool> comment(FeedPost post, String text) async {
    if (text.trim().isEmpty ||
        text.length > 2000 ||
        !pending.add('send:${post.id}')) {
      return false;
    }
    try {
      final created = await repository.comment(post.id, text.trim());
      final latest = find(post.id) ?? post;
      _emit(
        state.copyWith(
          posts: [
            for (final p in state.posts)
              p.id == post.id
                  ? latest.copyWith(commentCount: latest.commentCount + 1)
                  : p,
          ],
          comments: {
            ...state.comments,
            post.id: [...?state.comments[post.id], created],
          },
        ),
      );
      return true;
    } catch (e) {
      _fail();
      return false;
    } finally {
      pending.remove('send:${post.id}');
    }
  }

  Future<bool> delete(FeedPost post) async {
    if (!post.isMine || !pending.add('delete:${post.id}')) return false;
    try {
      await repository.delete(post.id);
      _emit(
        state.copyWith(
          posts: state.posts.where((p) => p.id != post.id).toList(),
        ),
      );
      return true;
    } catch (e) {
      _fail();
      return false;
    } finally {
      pending.remove('delete:${post.id}');
    }
  }

  Future<bool> report(FeedPost post, String reason) async {
    if (post.isMine || !pending.add('report:${post.id}')) return false;
    try {
      await repository.report(post, reason);
      return true;
    } catch (e) {
      _fail();
      return false;
    } finally {
      pending.remove('report:${post.id}');
    }
  }

  /// Lỗi đăng bài không phát qua [FeedsState.error]; composer tự báo lỗi.
  Future<bool> publish(String text, String? image) async {
    if ((text.trim().isEmpty && image == null) ||
        text.length > 2000 ||
        !pending.add('publish')) {
      return false;
    }
    try {
      final url = image == null ? null : await repository.upload(image);
      final post = await repository.publish(text.trim(), url);
      // Bài của mình không thuộc tab "Đang theo dõi" nên chỉ chèn vào
      // "Dành cho bạn" hoặc trang hồ sơ của chính mình.
      if (!state.onlyFollowing &&
          (authorId == null || authorId == post.authorId)) {
        _emit(state.copyWith(posts: [post, ...state.posts]));
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      pending.remove('publish');
    }
  }
}
