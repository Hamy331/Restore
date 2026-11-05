import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'public_profile_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../feeds/bloc/feeds/feeds_cubit.dart';
import '../../../feeds/repositories/feeds_repository.dart';
import '../../bloc/public_profile/public_profile_cubit.dart';
import '../../repositories/profile_repository.dart';

/// Trang hồ sơ của người khác: thông tin, nút theo dõi và bài viết.
class PublicProfileView extends StatelessWidget {
  const PublicProfileView({
    super.key,
    required this.userId,
    this.repository,
    this.feedsRepository,
  });
  final String userId;
  final ProfileRepository? repository;
  final FeedsRepository? feedsRepository;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            PublicProfileCubit(repository ?? ApiProfileRepository(), userId)
              ..load(),
      ),
      BlocProvider(
        create: (_) =>
            FeedsCubit(repository: feedsRepository, authorId: userId)..load(),
      ),
    ],
    child: const TResponsiveLayout(mobile: PublicProfileMobileView()),
  );
}
