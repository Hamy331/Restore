import 'package:equatable/equatable.dart';

import 'post_background.dart';
import 'post_listing_ref.dart';
import 'post_mention.dart';
import 'post_topic.dart';

/// Dữ liệu cần để mở màn hình viết bài: nền màu, chủ đề, người có thể gắn
/// thẻ và tin đăng của mình để gắn vào bài.
class PostComposerOptions extends Equatable {
  final List<PostBackground> backgrounds;
  final List<PostTopic> topics;
  final List<PostMention> mentionable;
  final List<PostListingRef> myListings;

  /// Số ảnh tối đa mỗi bài
  final int maxPhotos;

  /// Bài dài hơn số ký tự này thì không dùng nền màu được
  final int maxBackgroundLength;

  const PostComposerOptions({
    this.backgrounds = const [],
    this.topics = const [],
    this.mentionable = const [],
    this.myListings = const [],
    this.maxPhotos = 10,
    this.maxBackgroundLength = 150,
  });

  factory PostComposerOptions.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) => [
      for (final item in (json[key] as List? ?? const []))
        parse(Map<String, dynamic>.from(item as Map)),
    ];
    return PostComposerOptions(
      backgrounds: list('backgrounds', PostBackground.fromJson),
      topics: list('topics', PostTopic.fromJson),
      mentionable: list('mentionable', PostMention.fromJson),
      myListings: list('myListings', PostListingRef.fromJson),
      maxPhotos: json['maxPhotos'] as int? ?? 10,
      maxBackgroundLength: json['maxBackgroundLength'] as int? ?? 150,
    );
  }

  @override
  List<Object?> get props => [
    backgrounds,
    topics,
    mentionable,
    myListings,
    maxPhotos,
    maxBackgroundLength,
  ];
}
