import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../bloc/feeds/feeds_cubit.dart';
import '../../bloc/feeds/feeds_state.dart';
import '../../models/feed_models.dart';
import './widgets/feed_composer.dart';
import '../../widgets/feed_post_list.dart';
import '../../widgets/feed_search_bar.dart';
import '../../widgets/feed_shared.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';

class FeedsMobileView extends StatelessWidget {
  const FeedsMobileView({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTabHeader(
              title: 'Feeds',
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(AppIcons.back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              trailing: IconButton(
                icon: const Icon(AppIcons.notification),
                tooltip: l.notifications,
                onPressed: () => feedNotice(context, l.feedNotifications),
              ),
            ),
            const FeedSearchBar(),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: ColoredBox(
                  color: AppColors.surface,
                  child: BlocConsumer<FeedsCubit, FeedsState>(
                    listener: (context, state) {
                      if (state.error != null) {
                        feedNotice(
                          context,
                          AppLocalizations.of(context)!.feedActionError,
                        );
                      }
                    },
                    builder: (context, state) {
                      final cubit = context.read<FeedsCubit>();
                      if (state.loading && state.posts.isEmpty) {
                        return const Center(child: AppLoadingIndicator());
                      }
                      if (state.failed) {
                        return AppLoadErrorView(
                          title: l.feedLoadError,
                          onRetry: cubit.load,
                        );
                      }
                      return AppPullToRefresh(
                        onRefresh: () => cubit.load(),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) => feedScrollListener(cubit, n),
                          child: CustomScrollView(
                            // Dựng sẵn và tải ảnh trước khoảng 1,5 màn hình phía dưới
                            scrollCacheExtent: AppScroll.prefetchCacheExtent,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        _Tab(
                                          label: l.feedForYou,
                                          selected: !state.onlyFollowing,
                                          onTap: () => cubit.select(false),
                                        ),
                                        _Tab(
                                          label: l.feedFollowing,
                                          selected: state.onlyFollowing,
                                          onTap: () => cubit.select(true),
                                        ),
                                      ],
                                    ),
                                    _ComposePrompt(cubit: cubit, me: state.me),
                                    if (state.posts.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Text(
                                          state.searchQuery.isNotEmpty
                                              ? l.feedSearchEmpty
                                              : state.onlyFollowing
                                              ? l.feedFollowingEmpty
                                              : l.feedEmpty,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ...feedPostSlivers(cubit, state),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 180),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposePrompt extends StatelessWidget {
  const _ComposePrompt({required this.cubit, this.me});
  final FeedsCubit cubit;
  final FeedUser? me;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => showFeedComposer(context, cubit),
              child: Row(
                children: [
                  FeedAvatar.me(me, fallbackName: l.feedYourName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.feedCompose,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 2),
              child: ActionChip(
                avatar: const Icon(
                  AppIcons.addPhoto,
                  size: 15,
                  color: AppColors.success,
                ),
                label: Text(
                  l.feedAddPhoto,
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.background,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                onPressed: () => showFeedComposer(context, cubit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.textPrimary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    ),
  );
}
