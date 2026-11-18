import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'feeds_mobile_view.dart';
import '../../repositories/feeds_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/feeds/feeds_cubit.dart';
import 'widgets/feed_post_opener.dart';

class FeedsView extends StatelessWidget {
  const FeedsView({super.key, this.repository, this.openPostId});

  static const String path = '/feeds';

  /// Route mở sẵn bình luận của một bài (từ thông báo thích / bình luận)
  static String postLocation(String postId) => '$path?post=$postId';

  final FeedsRepository? repository;

  /// Bài cần mở bình luận khi vào trang (`/feeds?post=<id>`)
  final String? openPostId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => FeedsCubit(repository: repository)
      ..load()
      ..loadMe(),
    child: FeedPostOpener(
      postId: openPostId,
      child: const TResponsiveLayout(mobile: FeedsMobileView()),
    ),
  );
}
