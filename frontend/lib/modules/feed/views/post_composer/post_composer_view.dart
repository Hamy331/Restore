import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/post_composer/post_composer_cubit.dart';
import '../../bloc/post_composer/post_composer_state.dart';
import '../../repositories/feed_post_repository.dart';
import '../../repositories/recent_photos_repository.dart';
import 'post_composer_mobile_view.dart';

/// Route `/feeds/compose`: viết bài lên Bảng tin (chữ, nền màu, ảnh, gắn
/// tin đăng, chủ đề, gắn thẻ, vị trí, liên kết). Đăng xong trả về id bài.
class PostComposerView extends StatelessWidget {
  /// Mở sẵn lưới ảnh (bấm nút ảnh ở Bảng tin)
  final bool openPhotos;

  const PostComposerView({
    super.key,
    this.openPhotos = false,
    this.repository,
    this.recentPhotosRepository,
  });
  final FeedPostRepository? repository;
  final RecentPhotosRepository? recentPhotosRepository;

  static const String path = '/feeds/compose';

  static String location({bool openPhotos = false}) => Uri(
    path: path,
    queryParameters: openPhotos ? {'panel': 'photos'} : null,
  ).toString();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostComposerCubit(
        repository:
            repository ??
            (AppEnvironment.useMockData
                ? MockFeedPostRepository()
                : ApiFeedPostRepository()),
        recentPhotosRepository:
            recentPhotosRepository ??
            (AppEnvironment.useMockData
                ? MockRecentPhotosRepository()
                : DeviceRecentPhotosRepository()),
        initialPanel: openPhotos
            ? PostComposerPanel.photos
            : PostComposerPanel.none,
      )..start(),
      child: const TResponsiveLayout(mobile: PostComposerMobileView()),
    );
  }
}
