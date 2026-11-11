import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feeds/widgets/feed_shared.dart';
import '../../bloc/follow_list/follow_list_cubit.dart';
import '../../bloc/follow_list/follow_list_state.dart';
import '../../models/profile_models.dart';
import '../../repositories/profile_repository.dart';

/// Hai tab "Người theo dõi" / "Đang theo dõi" của [userId].
class FollowListMobileView extends StatelessWidget {
  const FollowListMobileView({
    super.key,
    required this.userId,
    this.initial = FollowListKind.followers,
    this.repository,
  });
  final String userId;
  final FollowListKind initial;
  final ProfileRepository? repository;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final repository = this.repository ?? ApiProfileRepository();
    return DefaultTabController(
      length: FollowListKind.values.length,
      initialIndex: initial.index,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          bottom: TabBar(
            tabs: [
              Tab(text: l.accFollowers),
              Tab(text: l.accFollowing),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final kind in FollowListKind.values)
              BlocProvider(
                create: (_) =>
                    FollowListCubit(repository, userId, kind)..load(),
                child: const _FollowList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _FollowList extends StatelessWidget {
  const _FollowList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FollowListCubit>();
    return BlocConsumer<FollowListCubit, FollowListState>(
      listenWhen: (_, state) => state.actionFailed,
      listener: (context, _) => feedNotice(context, l.feedActionError),
      builder: (context, state) {
        if (state.loading && state.users.isEmpty) {
          return const Center(child: AppLoadingIndicator());
        }
        if (state.failed) {
          return Center(
            child: TextButton(onPressed: cubit.load, child: Text(l.retry)),
          );
        }
        if (state.users.isEmpty) {
          return Center(
            child: Text(
              l.accFollowListEmpty,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return AppPullToRefresh(
          onRefresh: cubit.load,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 300) cubit.load(more: true);
              return false;
            },
            child: ListView.builder(
              itemCount: state.users.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.users.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: AppLoadingIndicator()),
                  );
                }
                final user = state.users[index];
                return ListTile(
                  leading: FeedAvatar(
                    name: user.fullName,
                    avatarUrl: user.avatarUrl,
                    size: 40,
                  ),
                  title: Text(
                    user.isMe ? l.feedYourName : user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('@${user.username}'),
                  onTap: () => user.isMe
                      ? context.go('/account')
                      : context.push('/users/${user.id}'),
                  trailing: user.isMe
                      ? null
                      : user.isFollowing
                      ? OutlinedButton(
                          onPressed: () => cubit.toggleFollow(user),
                          child: Text(l.feedUnfollow),
                        )
                      : FilledButton(
                          onPressed: () => cubit.toggleFollow(user),
                          child: Text(l.feedFollow),
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
