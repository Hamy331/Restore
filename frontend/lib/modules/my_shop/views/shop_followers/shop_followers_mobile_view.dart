import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/feeds/widgets/feed_shared.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/shop_followers_cubit.dart';

class ShopFollowersMobileView extends StatelessWidget {
  const ShopFollowersMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ShopFollowersCubit>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: BlocBuilder<ShopFollowersCubit, ShopFollowersState>(
          buildWhen: (a, b) => a.total != b.total || a.loading != b.loading,
          builder: (context, state) => Text(
            state.loading && state.followers.isEmpty
                ? l.msFollowersTitle
                : l.msFollowersTitleCount(state.total),
          ),
        ),
      ),
      body: BlocBuilder<ShopFollowersCubit, ShopFollowersState>(
        builder: (context, state) {
          if (state.loading && state.followers.isEmpty) {
            return const Center(child: AppLoadingIndicator());
          }
          if (state.failed) {
            return Center(
              child: TextButton(onPressed: cubit.load, child: Text(l.retry)),
            );
          }
          if (state.followers.isEmpty) {
            return FeedbackView(
              icon: AppIcons.audienceFollowers,
              title: l.msFollowersEmpty,
              message: l.msFollowersEmptyHint,
            );
          }
          final date = DateFormat('dd/MM/yyyy');
          return AppPullToRefresh(
            onRefresh: cubit.load,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 300) cubit.load(more: true);
                return false;
              },
              child: ListView.builder(
                itemCount: state.followers.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.followers.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: AppLoadingIndicator()),
                    );
                  }
                  final user = state.followers[index];
                  final since = user.followedAt;
                  return ListTile(
                    leading: FeedAvatar(
                      name: user.fullName,
                      avatarUrl: user.avatarUrl,
                      size: 40,
                    ),
                    title: Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('@${user.username}'),
                    trailing: since == null
                        ? null
                        : Text(
                            l.msFollowedSince(date.format(since.toLocal())),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                    onTap: () => context.push('/users/${user.id}'),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
