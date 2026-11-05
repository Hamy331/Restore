import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feeds/bloc/feeds/feeds_cubit.dart';
import '../../../feeds/widgets/feed_post_list.dart';
import '../../bloc/public_profile/public_profile_cubit.dart';
import '../../bloc/public_profile/public_profile_state.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/profile_posts.dart';

class PublicProfileMobileView extends StatelessWidget {
  const PublicProfileMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PublicProfileCubit>();
    final posts = context.read<FeedsCubit>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface),
      body: BlocConsumer<PublicProfileCubit, PublicProfileState>(
        listenWhen: (_, state) => state.actionFailed,
        listener: (context, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.feedActionError))),
        builder: (context, state) {
          if (state.failed) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.accUserNotFound),
                  TextButton(onPressed: cubit.load, child: Text(l.retry)),
                ],
              ),
            );
          }
          final profile = state.profile;
          void openFollows(FollowListKind kind) =>
              context.push('/users/${cubit.userId}/follows?tab=${kind.name}');
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: RefreshIndicator(
                onRefresh: () => Future.wait([cubit.load(), posts.load()]),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) => feedScrollListener(posts, n),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                        sliver: SliverToBoxAdapter(
                          child: ProfileHeader(
                            profile: profile,
                            onFollowingTap: () =>
                                openFollows(FollowListKind.following),
                            onFollowersTap: () =>
                                openFollows(FollowListKind.followers),
                            action: profile == null
                                ? null
                                : SizedBox(
                                    width: double.infinity,
                                    child: profile.isFollowing
                                        ? OutlinedButton(
                                            onPressed: state.following
                                                ? null
                                                : cubit.toggleFollow,
                                            child: Text(l.feedUnfollow),
                                          )
                                        : FilledButton(
                                            onPressed: state.following
                                                ? null
                                                : cubit.toggleFollow,
                                            child: Text(l.feedFollow),
                                          ),
                                  ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            l.accPosts,
                            style: const TextStyle(
                              fontFamily: profileFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Divider(color: AppColors.border),
                      ),
                      ProfilePostsSliver(cubit: posts),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
