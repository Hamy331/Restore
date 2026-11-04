import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/enums/post_audience.dart';
import 'package:restore/modules/location/models/area_option.dart';

import '../../models/post_background.dart';
import '../../models/post_listing_ref.dart';
import '../../models/post_mention.dart';
import '../../models/post_topic.dart';
import '../../repositories/feed_post_repository.dart';
import '../../repositories/recent_photos_repository.dart';
import 'post_composer_state.dart';

/// Màn hình viết bài lên Bảng tin: chữ (có thể kèm nền màu), ảnh, chủ đề,
/// tin đăng của mình, gắn thẻ, vị trí và liên kết.
class PostComposerCubit extends Cubit<PostComposerState> {
  PostComposerCubit({
    required FeedPostRepository repository,
    required RecentPhotosRepository recentPhotosRepository,
    PostComposerPanel initialPanel = PostComposerPanel.none,
  }) : _repository = repository,
       _recentPhotosRepository = recentPhotosRepository,
       super(PostComposerState(panel: initialPanel));

  final FeedPostRepository _repository;
  final RecentPhotosRepository _recentPhotosRepository;

  @override
  void emit(PostComposerState state) {
    if (!isClosed) super.emit(state);
  }

  Future<void> start() async {
    emit(state.copyWith(status: PostComposerStatus.loading));
    try {
      final (options, recentPhotos) = await (
        _repository.getComposerOptions(),
        _recentPhotosRepository.getRecentPhotos(),
      ).wait;
      emit(
        state.copyWith(
          status: PostComposerStatus.ready,
          options: options,
          recentPhotos: recentPhotos,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: PostComposerStatus.failure));
    }
  }

  void contentChanged(String content) {
    if (content == state.draft.content) return;
    var draft = state.draft.copyWith(content: content);
    // Bài dài quá thì bỏ nền màu cho dễ đọc
    if (content.length > state.options.maxBackgroundLength) {
      draft = draft.copyWith(background: () => null);
    }
    emit(state.copyWith(draft: draft));
  }

  void setAudience(PostAudience audience) =>
      emit(state.copyWith(draft: state.draft.copyWith(audience: audience)));

  void toggleBackgrounds() => emit(
    state.copyWith(
      showBackgrounds: !state.showBackgrounds,
      panel: PostComposerPanel.none,
    ),
  );

  /// null là bỏ nền màu
  void selectBackground(PostBackground? background) {
    if (background != null && !state.canUseBackground) return;
    emit(
      state.copyWith(draft: state.draft.copyWith(background: () => background)),
    );
  }

  void openPanel(PostComposerPanel panel) => emit(
    state.copyWith(
      panel: state.panel == panel ? PostComposerPanel.none : panel,
      showBackgrounds: false,
    ),
  );

  void closePanel() {
    if (state.panel != PostComposerPanel.none) {
      emit(state.copyWith(panel: PostComposerPanel.none));
    }
  }

  /// Chọn/bỏ chọn ảnh ở lưới ảnh gần đây. Trả về false khi đã đủ số ảnh.
  bool togglePhoto(String path) {
    final photos = [...state.draft.photos];
    if (!photos.remove(path)) {
      if (state.remainingPhotos <= 0) return false;
      photos.add(path);
    }
    _setPhotos(photos);
    return true;
  }

  /// Thêm ảnh từ máy ảnh hoặc thư viện, bỏ phần vượt quá giới hạn
  void addPhotos(List<String> paths) {
    final photos = [
      ...state.draft.photos,
      for (final path in paths)
        if (!state.draft.photos.contains(path)) path,
    ].take(state.options.maxPhotos).toList();
    _setPhotos(photos);
  }

  void removePhoto(String path) =>
      _setPhotos([...state.draft.photos]..remove(path));

  void setTopic(PostTopic? topic) =>
      emit(state.copyWith(draft: state.draft.copyWith(topic: () => topic)));

  void setListing(PostListingRef? listing) =>
      emit(state.copyWith(draft: state.draft.copyWith(listing: () => listing)));

  void toggleMention(PostMention mention) {
    final mentions = [...state.draft.mentions];
    if (!mentions.remove(mention)) mentions.add(mention);
    emit(state.copyWith(draft: state.draft.copyWith(mentions: mentions)));
  }

  void setLocation(AreaOption? location) => emit(
    state.copyWith(draft: state.draft.copyWith(location: () => location)),
  );

  void setLink(String? url) {
    final value = url?.trim();
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          linkUrl: () => value == null || value.isEmpty ? null : value,
        ),
      ),
    );
  }

  /// Đăng bài; trả về id bài, null khi lỗi
  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    emit(state.copyWith(isSubmitting: true));
    try {
      final id = await _repository.createPost(state.draft);
      emit(state.copyWith(isSubmitting: false));
      return id;
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
      return null;
    }
  }

  void _setPhotos(List<String> photos) {
    var draft = state.draft.copyWith(photos: photos);
    // Có ảnh thì không dùng nền màu
    if (photos.isNotEmpty) draft = draft.copyWith(background: () => null);
    emit(
      state.copyWith(
        draft: draft,
        showBackgrounds: photos.isEmpty && state.showBackgrounds,
      ),
    );
  }
}
