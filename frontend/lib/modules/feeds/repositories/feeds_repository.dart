import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../services/image_upload_service.dart';
import '../models/feed_models.dart';

class FeedsRepository {
  FeedsRepository({Dio? dio, ImageUploadService? uploader})
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

  Future<FeedUser> me() async => FeedUser.fromJson(await _get('/users/me'));

  /// [authorId] khác null thì chỉ lấy bài của tác giả đó (trang hồ sơ).
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

  Future<FeedPost> publish(String text, String? imageUrl) async =>
      FeedPost.fromJson(
        Map<String, dynamic>.from(
          (await _dio.post(
            '/feeds',
            data: {'text': text, 'imageUrl': imageUrl},
          )).data['data'],
        ),
      );

  Future<void> delete(String postId) async {
    await _dio.delete('/feeds/$postId');
  }

  Future<({bool liked, int likes})> likePost(String id, bool value) =>
      _like('/feeds/$id/like', value);

  Future<({bool liked, int likes})> likeComment(String id, bool value) =>
      _like('/feed-comments/$id/like', value);

  Future<({bool liked, int likes})> _like(String path, bool value) async {
    final data = (await _dio.request(
      path,
      options: Options(method: value ? 'PUT' : 'DELETE'),
    )).data['data'];
    return (
      liked: data['likedByMe'] == true,
      likes: (data['likeCount'] as num).toInt(),
    );
  }

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

  Future<FeedComment> comment(String postId, String text) async =>
      FeedComment.fromJson(
        Map<String, dynamic>.from(
          (await _dio.post(
            '/feeds/$postId/comments',
            data: {'text': text},
          )).data['data'],
        ),
      );

  Future<void> follow(String userId, bool value) async {
    await _dio.request(
      '/users/$userId/follow',
      options: Options(method: value ? 'POST' : 'DELETE'),
    );
  }

  /// Báo cáo bài viết qua luồng kiểm duyệt hiện có: đối tượng là tác giả,
  /// bằng chứng ghi rõ bài viết bị báo cáo.
  Future<void> report(FeedPost post, String reason) async {
    final content = post.text.isNotEmpty ? post.text : post.image ?? '';
    await _dio.post(
      '/content/reports',
      data: {
        'targetType': 'USER',
        'targetId': post.authorId,
        'reason': reason,
        'evidence': 'Bài viết bảng tin ${post.id}: $content',
      },
    );
  }

  Future<String> upload(String path) =>
      (_uploader ?? ImageUploadService(dio: _dio)).upload(path);
}
