import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../services/image_upload_service.dart';
import '../models/feed_models.dart';

typedef LikeResult = ({bool liked, int likes});

/// Hợp đồng dữ liệu bảng tin
abstract class FeedsRepository {
  Future<FeedUser> me();

  /// [authorId] khác null thì chỉ lấy bài của tác giả đó (trang hồ sơ).
  Future<FeedPage<FeedPost>> posts({
    bool following = false,
    String? authorId,
    String? cursor,
  });
  Future<FeedPost> publish(String text, String? imageUrl);
  Future<void> delete(String postId);
  Future<LikeResult> likePost(String id, bool value);
  Future<LikeResult> likeComment(String id, bool value);
  Future<FeedPage<FeedComment>> comments(String postId, {String? cursor});
  Future<FeedComment> comment(
    String postId,
    String text, {
    String? imageUrl,
    String? parentId,
  });
  Future<void> follow(String userId, bool value);
  Future<void> report(FeedPost post, String reason);
  Future<String> upload(String path);
}

/// Gọi backend `/feeds`, `/feed-comments`, `/users/:id/follow`
class ApiFeedsRepository implements FeedsRepository {
  ApiFeedsRepository({Dio? dio, ImageUploadService? uploader})
    : _dio = dio ?? ApiClient().dio,
      _uploader = uploader;
  final Dio _dio;
  final ImageUploadService? _uploader;

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async => Map<String, dynamic>.from(
    (await _dio.get(path, queryParameters: query)).data['data'],
  );

  @override
  Future<FeedUser> me() async => FeedUser.fromJson(await _get('/users/me'));

  @override
  Future<FeedPage<FeedPost>> posts({
    bool following = false,
    String? authorId,
    String? cursor,
  }) async {
    final data = await _get('/feeds', {
      'tab': following ? 'following' : 'for-you',
      'authorId': ?authorId,
      'cursor': ?cursor,
    });
    return FeedPage([
      for (final j in data['items'] as List)
        FeedPost.fromJson(Map<String, dynamic>.from(j)),
    ], data['nextCursor']);
  }

  @override
  Future<FeedPost> publish(String text, String? imageUrl) async =>
      FeedPost.fromJson(
        Map<String, dynamic>.from(
          (await _dio.post(
            '/feeds',
            data: {'text': text, 'imageUrl': imageUrl},
          )).data['data'],
        ),
      );

  @override
  Future<void> delete(String postId) async {
    await _dio.delete('/feeds/$postId');
  }

  @override
  Future<LikeResult> likePost(String id, bool value) =>
      _like('/feeds/$id/like', value);

  @override
  Future<LikeResult> likeComment(String id, bool value) =>
      _like('/feed-comments/$id/like', value);

  Future<LikeResult> _like(String path, bool value) async {
    final data = (await _dio.request(
      path,
      options: Options(method: value ? 'PUT' : 'DELETE'),
    )).data['data'];
    return (
      liked: data['likedByMe'] == true,
      likes: (data['likeCount'] as num).toInt(),
    );
  }

  @override
  Future<FeedPage<FeedComment>> comments(
    String postId, {
    String? cursor,
  }) async {
    final data = await _get('/feeds/$postId/comments', {'cursor': ?cursor});
    return FeedPage([
      for (final j in data['items'] as List)
        FeedComment.fromJson(Map<String, dynamic>.from(j)),
    ], data['nextCursor']);
  }

  @override
  Future<FeedComment> comment(
    String postId,
    String text, {
    String? imageUrl,
    String? parentId,
  }) async => FeedComment.fromJson(
    Map<String, dynamic>.from(
      (await _dio.post(
        '/feeds/$postId/comments',
        data: {'text': text, 'imageUrl': ?imageUrl, 'parentId': ?parentId},
      )).data['data'],
    ),
  );

  @override
  Future<void> follow(String userId, bool value) async {
    await _dio.request(
      '/users/$userId/follow',
      options: Options(method: value ? 'POST' : 'DELETE'),
    );
  }

  /// Báo cáo đúng bài viết để admin có thể xem xét và gỡ nội dung vi phạm.
  @override
  Future<void> report(FeedPost post, String reason) async {
    final content = post.text.isNotEmpty ? post.text : post.image ?? '';
    await _dio.post(
      '/content/reports',
      data: {
        'targetType': 'FEED_POST',
        'targetId': post.id,
        'reason': reason,
        'evidence': 'Bài viết bảng tin ${post.id}: $content',
      },
    );
  }

  @override
  Future<String> upload(String path) =>
      (_uploader ?? ImageUploadService(dio: _dio)).upload(path);
}
