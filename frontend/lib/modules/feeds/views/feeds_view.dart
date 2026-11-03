import '../repositories/feeds_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_header_palette.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/views/home/widgets/home_header_icon_button.dart';
import '../bloc/feeds_cubit.dart';
import 'widgets/feed_composer.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/feed_shared.dart';

class FeedsView extends StatelessWidget {
  const FeedsView({super.key, this.repository});
  final FeedsRepository? repository;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => FeedsCubit(repository: repository)..load(),
    child: const _FeedsPage(),
  );
}

class _FeedsPage extends StatelessWidget {
  const _FeedsPage();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppHeaderPalette.gradient),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.feedsTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      HomeHeaderIconButton(
                        icon: AppIcons.notification,
                        tooltip: l.notifications,
                        onTap: () => feedNotice(context, l.feedNotifications),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: BlocConsumer<FeedsCubit, FeedsState>(
                        listener: (context, state) {
                          if (state.error != null) {
                            feedNotice(
                              context,
                              AppLocalizations.of(context)!.feedLoadError,
                            );
                          }
                        },
                        builder: (context, state) {
                          final cubit = context.read<FeedsCubit>();
                          if (state.loading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state.failed) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l.feedLoadError),
                                  TextButton(
                                    onPressed: cubit.load,
                                    child: Text(l.retry),
                                  ),
                                ],
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () => cubit.load(),
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (n) {
                                if (n.metrics.extentAfter < 300) {
                                  cubit.loadMore();
                                }
                                return false;
                              },
                              child: CustomScrollView(
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
                                        _ComposePrompt(cubit: cubit),
                                        if (state.visible.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(32),
                                            child: Text(
                                              state.onlyFollowing
                                                  ? l.feedFollowingEmpty
                                                  : l.feedEmpty,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => RepaintBoundary(
                                        child: FeedPostCard(
                                          post: state.visible[index],
                                          cubit: cubit,
                                        ),
                                      ),
                                      childCount: state.visible.length,
                                    ),
                                  ),
                                  if (state.loadingMore)
                                    const SliverToBoxAdapter(
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
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
        ),
      ),
    );
  }
}

class _ComposePrompt extends StatelessWidget {
  const _ComposePrompt({required this.cubit});
  final FeedsCubit cubit;
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
                  FeedAvatar(name: l.feedYourName),
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
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    ),
  );
}
