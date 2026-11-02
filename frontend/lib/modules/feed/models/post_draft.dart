import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/post_audience.dart';
import 'package:restore/modules/location/models/area_option.dart';

import 'post_background.dart';
import 'post_listing_ref.dart';
import 'post_mention.dart';
import 'post_topic.dart';

/// Bài viết đang soạn trên Bảng tin.
class PostDraft extends Equatable {
  final String content;
  final PostAudience audience;
  final PostBackground? background;

  /// Đường dẫn ảnh trên máy, theo thứ tự đã chọn (ảnh đầu là ảnh bìa)
  final List<String> photos;
  final PostTopic? topic;
  final PostListingRef? listing;
  final List<PostMention> mentions;
  final AreaOption? location;
  final String? linkUrl;

  const PostDraft({
    this.content = '',
    this.audience = PostAudience.everyone,
    this.background,
    this.photos = const [],
    this.topic,
    this.listing,
    this.mentions = const [],
    this.location,
    this.linkUrl,
  });

  bool get hasContent =>
      content.trim().isNotEmpty || photos.isNotEmpty || listing != null;

  PostDraft copyWith({
    String? content,
    PostAudience? audience,
    PostBackground? Function()? background,
    List<String>? photos,
    PostTopic? Function()? topic,
    PostListingRef? Function()? listing,
    List<PostMention>? mentions,
    AreaOption? Function()? location,
    String? Function()? linkUrl,
  }) => PostDraft(
    content: content ?? this.content,
    audience: audience ?? this.audience,
    background: background != null ? background() : this.background,
    photos: photos ?? this.photos,
    topic: topic != null ? topic() : this.topic,
    listing: listing != null ? listing() : this.listing,
    mentions: mentions ?? this.mentions,
    location: location != null ? location() : this.location,
    linkUrl: linkUrl != null ? linkUrl() : this.linkUrl,
  );

  /// Body gửi lên API. Ảnh được tải lên kho ảnh trước, [photoUrls] là
  /// đường dẫn sau khi tải.
  Map<String, dynamic> toJson({List<String> photoUrls = const []}) => {
    'content': content.trim(),
    'audience': audience.apiValue,
    'backgroundId': ?background?.id,
    'photos': photoUrls,
    'topicId': ?topic?.id,
    'listingId': ?listing?.id,
    'mentionUserIds': [for (final mention in mentions) mention.userId],
    if (location case final area?)
      'location': {'code': area.code, 'label': area.label},
    'linkUrl': ?linkUrl,
  };

  @override
  List<Object?> get props => [
    content,
    audience,
    background,
    photos,
    topic,
    listing,
    mentions,
    location,
    linkUrl,
  ];
}
