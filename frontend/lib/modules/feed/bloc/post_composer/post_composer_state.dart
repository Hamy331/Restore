import 'package:equatable/equatable.dart';

import '../../models/post_composer_options.dart';
import '../../models/post_draft.dart';

enum PostComposerStatus { loading, ready, failure }

/// Khung bên dưới thanh công cụ thay cho bàn phím
enum PostComposerPanel { none, photos, emoji }

class PostComposerState extends Equatable {
  final PostComposerStatus status;
  final PostComposerOptions options;
  final PostDraft draft;
  final PostComposerPanel panel;

  /// Đang mở hàng chọn nền màu (nút "Aa")
  final bool showBackgrounds;
  final List<String> recentPhotos;
  final bool isSubmitting;

  const PostComposerState({
    this.status = PostComposerStatus.loading,
    this.options = const PostComposerOptions(),
    this.draft = const PostDraft(),
    this.panel = PostComposerPanel.none,
    this.showBackgrounds = false,
    this.recentPhotos = const [],
    this.isSubmitting = false,
  });

  /// Nền màu chỉ dùng cho bài ngắn, chưa có ảnh
  bool get canUseBackground =>
      draft.photos.isEmpty &&
      draft.content.length <= options.maxBackgroundLength;

  bool get canSubmit => draft.hasContent && !isSubmitting;

  int get remainingPhotos => options.maxPhotos - draft.photos.length;

  PostComposerState copyWith({
    PostComposerStatus? status,
    PostComposerOptions? options,
    PostDraft? draft,
    PostComposerPanel? panel,
    bool? showBackgrounds,
    List<String>? recentPhotos,
    bool? isSubmitting,
  }) => PostComposerState(
    status: status ?? this.status,
    options: options ?? this.options,
    draft: draft ?? this.draft,
    panel: panel ?? this.panel,
    showBackgrounds: showBackgrounds ?? this.showBackgrounds,
    recentPhotos: recentPhotos ?? this.recentPhotos,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );

  @override
  List<Object?> get props => [
    status,
    options,
    draft,
    panel,
    showBackgrounds,
    recentPhotos,
    isSubmitting,
  ];
}
