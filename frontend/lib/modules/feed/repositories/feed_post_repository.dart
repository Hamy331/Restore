import 'package:restore/core/network/api_client.dart';

import '../data/feed_mock_data.dart';
import '../models/post_composer_options.dart';
import '../models/post_draft.dart';

/// Nguồn dữ liệu đăng bài lên Bảng tin.
abstract class FeedPostRepository {
  /// Nền màu, chủ đề, người gắn thẻ được và tin đăng của mình
  Future<PostComposerOptions> getComposerOptions();

  /// Đăng bài, trả về id bài vừa đăng
  Future<String> createPost(PostDraft draft);
}

class MockFeedPostRepository implements FeedPostRepository {
  MockFeedPostRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  static int _nextId = 1;

  @override
  Future<PostComposerOptions> getComposerOptions() async {
    await Future<void>.delayed(latency);
    return PostComposerOptions.fromJson(FeedMockData.composerOptions());
  }

  @override
  Future<String> createPost(PostDraft draft) async {
    await Future<void>.delayed(latency * 2);
    return 'post-${_nextId++}';
  }
}

/// Gọi backend (cần đăng nhập):
/// - `GET /feed/composer-options` → `{ data: PostComposerOptions }`
/// - `POST /feed/posts` body [PostDraft.toJson] → `{ data: { id } }`.
///   Ảnh tải lên kho ảnh (Supabase Storage) trước rồi gửi URL trong `photos`.
class ApiFeedPostRepository implements FeedPostRepository {
  ApiFeedPostRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<PostComposerOptions> getComposerOptions() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/feed/composer-options',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return PostComposerOptions.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<String> createPost(PostDraft draft) async {
    // TODO: tải draft.photos lên kho ảnh rồi truyền photoUrls
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/feed/posts',
      data: draft.toJson(),
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return '${data['id']}';
  }
}
