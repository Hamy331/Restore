import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/feed_models.dart';
import '../repositories/feeds_repository.dart';
export '../models/feed_models.dart';

class FeedsState {
  const FeedsState({
    this.posts = const [],
    this.onlyFollowing = false,
    this.loading = false,
    this.failed = false,
    this.loadingMore = false,
    this.error,
  });
  final List<FeedPost> posts;
  final bool onlyFollowing, loading, failed, loadingMore;
  final String? error;
  Set<String> get following =>
      posts.where((p) => p.following).map((p) => p.authorId).toSet();
  List<FeedPost> get visible => posts;
}

class FeedsCubit extends Cubit<FeedsState> {
  FeedsCubit({FeedsRepository? repository})
    : repository = repository ?? FeedsRepository(),
      super(const FeedsState());
  final FeedsRepository repository;
  String? cursor;
  int generation = 0;
  final Set<String> pending = {};
  void notify({String? error}) {
    if (!isClosed) {
      emit(
        FeedsState(
          posts: List.of(state.posts),
          onlyFollowing: state.onlyFollowing,
          error: error,
        ),
      );
    }
  }

  Future<void> load({bool? following}) async {
    final tab = following ?? state.onlyFollowing, version = ++generation;
    emit(FeedsState(posts: state.posts, onlyFollowing: tab, loading: true));
    try {
      final data = await repository.get('/feeds', {
        'tab': tab ? 'following' : 'for-you',
      });
      if (isClosed || version != generation) return;
      cursor = data['nextCursor'];
      emit(
        FeedsState(
          posts: (data['items'] as List)
              .map((j) => FeedPost.fromJson(j))
              .toList(),
          onlyFollowing: tab,
        ),
      );
    } catch (e) {
      if (!isClosed && version == generation) {
        emit(FeedsState(onlyFollowing: tab, failed: true));
      }
    }
  }

  Future<void> loadMore() async {
    if (cursor == null || state.loadingMore || state.loading) return;
    final version = generation;
    emit(
      FeedsState(
        posts: state.posts,
        onlyFollowing: state.onlyFollowing,
        loadingMore: true,
      ),
    );
    try {
      final data = await repository.get('/feeds', {
        'tab': state.onlyFollowing ? 'following' : 'for-you',
        'cursor': cursor,
      });
      if (isClosed || version != generation) return;
      cursor = data['nextCursor'];
      final ids = state.posts.map((p) => p.id).toSet();
      emit(
        FeedsState(
          posts: [
            ...state.posts,
            ...(data['items'] as List)
                .map((j) => FeedPost.fromJson(j))
                .where((p) => !ids.contains(p.id)),
          ],
          onlyFollowing: state.onlyFollowing,
        ),
      );
    } catch (e) {
      if (!isClosed && version == generation) notify(error: e.toString());
    }
  }

  void select(bool following) {
    load(following: following);
  }

  Future<void> toggleFollow(String authorId) async {
    if (!pending.add('follow:$authorId')) return;
    try {
      final value = !state.following.contains(authorId);
      await repository.follow(authorId, value);
      for (final p in state.posts) {
        if (p.authorId == authorId) p.following = value;
      }
      await load();
    } catch (e) {
      notify(error: e.toString());
    } finally {
      pending.remove('follow:$authorId');
    }
  }

  Future<void> toggleLike(FeedPost post) async {
    if (!pending.add(post.id)) return;
    try {
      final data = await repository.like('/feeds/${post.id}/like', !post.liked);
      post.liked = data['likedByMe'];
      post.likes = data['likeCount'];
      notify();
    } catch (e) {
      notify(error: e.toString());
    } finally {
      pending.remove(post.id);
    }
  }

  Future<void> toggleCommentLike(FeedComment comment) async {
    if (!pending.add(comment.id)) return;
    try {
      final data = await repository.like(
        '/feed-comments/${comment.id}/like',
        !comment.liked,
      );
      comment.liked = data['likedByMe'];
      comment.likes = data['likeCount'];
      notify();
    } catch (e) {
      notify(error: e.toString());
    } finally {
      pending.remove(comment.id);
    }
  }

  final Map<String, String?> commentCursors = {};
  FeedPost? find(String id) {
    for (final p in state.posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> comments(String id, {bool more = false}) async {
    if (!pending.add('comments:$id')) return;
    notify();
    try {
      final data = await repository.get('/feeds/$id/comments', {
        if (more && commentCursors[id] != null) 'cursor': commentCursors[id],
      });
      final p = find(id);
      if (p != null) {
        final incoming = (data['items'] as List).map(
          (j) => FeedComment.fromJson(j),
        );
        final merged = {
          for (final c in [if (more) ...p.comments, ...incoming]) c.id: c,
        };
        p.comments = merged.values.toList();
        commentCursors[id] = data['nextCursor'];
        notify();
      }
    } catch (e) {
      notify(error: e.toString());
    } finally {
      pending.remove('comments:$id');
      notify();
    }
  }

  Future<bool> comment(FeedPost post, String text) async {
    if (text.trim().isEmpty ||
        text.length > 2000 ||
        !pending.add('send:${post.id}')) {
      return false;
    }
    try {
      final result = await repository.post('/feeds/${post.id}/comments', {
        'text': text.trim(),
      });
      post.commentCount++;
      post.comments.add(
        FeedComment.fromJson(Map<String, dynamic>.from(result)),
      );
      notify();
      return true;
    } catch (e) {
      notify(error: e.toString());
      return false;
    } finally {
      pending.remove('send:${post.id}');
    }
  }

  Future<bool> publish(String text, String? image) async {
    if ((text.trim().isEmpty && image == null) ||
        text.length > 2000 ||
        !pending.add('publish')) {
      return false;
    }
    try {
      final url = image == null ? null : await repository.upload(image);
      await repository.post('/feeds', {'text': text.trim(), 'imageUrl': url});
      await load(following: false);
      return true;
    } catch (e) {
      notify(error: e.toString());
      return false;
    } finally {
      pending.remove('publish');
    }
  }
}
