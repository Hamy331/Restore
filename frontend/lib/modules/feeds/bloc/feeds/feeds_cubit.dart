import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/feed_models.dart';
import '../../repositories/feeds_repository.dart';
import 'feeds_state.dart';

class FeedsCubit extends Cubit<FeedsState> {
  /// [authorId] khác null: danh sách bài của một người (trang hồ sơ), không
  /// có tab "Đang theo dõi".
  FeedsCubit({FeedsRepository? repository, this.authorId})
    : repository = repository ?? ApiFeedsRepository(),
      super(const FeedsState());
  final FeedsRepository repository;
  final String? authorId;

  /// Con trỏ trang tiếp theo của danh sách bài và số thế hệ của lần tải
  /// gần nhất (bỏ kết quả của lần tải cũ khi người dùng đã đổi tab).
  String? _cursor;
  int _generation = 0;

  void _emit(FeedsState next) {
    if (!isClosed) emit(next);
  }

  void _fail() => _emit(state.copyWith(error: FeedError.action));

  /// Đánh dấu [key] đang chạy; trả `false` nếu thao tác đó đã chạy rồi.
  bool _begin(String key) {
    if (state.isPending(key)) return false;
    _emit(state.copyWith(pending: {...state.pending, key}));
    return true;
  }

  void _end(String key) =>
      _emit(state.copyWith(pending: {...state.pending}..remove(key)));

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
    final tab = following ?? state.onlyFollowing, version = ++_generation;
    final keep = tab == state.onlyFollowing && !state.failed;
    _emit(
      state.copyWith(
        posts: keep ? state.posts : const [],
        onlyFollowing: tab,
        loading: true,
        failed: false,
        loadingMore: false,
        loadMoreFailed: false,
      ),
    );
    try {
      final page = await repository.posts(following: tab, authorId: authorId);
      if (isClosed || version != _generation) return;
      _cursor = page.nextCursor;
      _emit(state.copyWith(posts: page.items, loading: false));
    } catch (e) {
      if (isClosed || version != _generation) return;
      _emit(
        keep && state.posts.isNotEmpty
            ? state.copyWith(loading: false, error: FeedError.action)
            : state.copyWith(posts: const [], loading: false, failed: true),
      );
    }
  }

  /// Lỗi thì dừng tự tải thêm khi cuộn; người dùng bấm "Thử lại" để gọi
  /// [loadMore] với `retry: true`.
  Future<void> loadMore({bool retry = false}) async {
    if (_cursor == null || state.loadingMore || state.loading) return;
    if (state.loadMoreFailed && !retry) return;
    final version = _generation;
    _emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await repository.posts(
        following: state.onlyFollowing,
        authorId: authorId,
        cursor: _cursor,
      );
      if (isClosed || version != _generation) return;
      _cursor = page.nextCursor;
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
      if (isClosed || version != _generation) return;
      _emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  void select(bool following) {
    if (following == state.onlyFollowing && !state.failed) return;
    load(following: following);
  }

  Future<void> toggleFollow(String authorId) async {
    final key = 'follow:$authorId';
    if (!_begin(key)) return;
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
      _end(key);
    }
  }

  /// Cập nhật giao diện ngay, sau đó đồng bộ theo server; lỗi thì hoàn tác.
  Future<void> toggleLike(FeedPost post) async {
    final key = 'like:${post.id}';
    if (!_begin(key)) return;
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
      _end(key);
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
    final key = 'like:${comment.id}';
    if (!_begin(key)) return;
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
      _end(key);
    }
  }

  Future<void> loadComments(String id, {bool more = false}) async {
    final key = 'comments:$id';
    if (!_begin(key)) return;
    try {
      final page = await repository.comments(
        id,
        cursor: more ? state.commentCursors[id] : null,
      );
      final merged = {
        for (final c in [if (more) ...?state.comments[id], ...page.items])
          c.id: c,
      };
      _emit(
        state.copyWith(
          comments: {...state.comments, id: merged.values.toList()},
          commentCursors: {...state.commentCursors, id: page.nextCursor},
        ),
      );
    } catch (e) {
      _fail();
    } finally {
      _end(key);
    }
  }

  Future<bool> comment(FeedPost post, String text) async {
    final key = 'send:${post.id}';
    if (text.trim().isEmpty || text.length > 2000 || !_begin(key)) {
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
      _end(key);
    }
  }

  Future<bool> delete(FeedPost post) async {
    final key = 'delete:${post.id}';
    if (!post.isMine || !_begin(key)) return false;
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
      _end(key);
    }
  }

  Future<bool> report(FeedPost post, String reason) async {
    final key = 'report:${post.id}';
    if (post.isMine || !_begin(key)) return false;
    try {
      await repository.report(post, reason);
      return true;
    } catch (e) {
      _fail();
      return false;
    } finally {
      _end(key);
    }
  }

  /// Lỗi đăng bài không phát qua [FeedsState.error]; composer tự báo lỗi.
  Future<bool> publish(String text, String? image) async {
    const key = 'publish';
    if ((text.trim().isEmpty && image == null) ||
        text.length > 2000 ||
        !_begin(key)) {
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
      _end(key);
    }
  }
}
