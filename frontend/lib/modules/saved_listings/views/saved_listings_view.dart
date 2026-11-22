import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../bloc/saved_listings_cubit.dart';
import '../repositories/saved_listings_repository.dart';

/// Route `/saved`: tin người dùng đã lưu (Tài khoản → Đã lưu).
/// [recent] = true: route `/recently-viewed`, các tin vừa mở xem (Tài khoản → Xem gần đây).
class SavedListingsView extends StatelessWidget {
  const SavedListingsView({super.key, this.repository, this.recent = false});

  /// Thay nguồn dữ liệu khi test
  final SavedListingsRepository? repository;
  final bool recent;

  static const String path = '/saved';
  static const String recentPath = '/recently-viewed';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SavedListingsCubit(
      repository:
          repository ??
          (recent
              ? SavedListingsRepository.recentlyViewed()
              : SavedListingsRepository()),
    )..start(),
    child: TResponsiveLayout(mobile: _SavedListingsBody(recent: recent)),
  );
}

class _SavedListingsBody extends StatelessWidget {
  const _SavedListingsBody({required this.recent});

  final bool recent;

  static const double _sidePadding = 16;

  Future<void> _openDetail(BuildContext context, ListingCardItem item) async {
    final cubit = context.read<SavedListingsCubit>();
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite != null) cubit.syncFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SavedListingsCubit>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(AppIcons.back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        centerTitle: true,
        title: Text(
          recent ? l10n.accRecentlyViewed : l10n.savedListings,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: BlocBuilder<SavedListingsCubit, SavedListingsState>(
        builder: (context, state) {
          final Widget content = switch (state.status) {
            SavedListingsStatus.loading => const SliverToBoxAdapter(
              child: AppListingGridSkeleton(),
            ),
            SavedListingsStatus.failure => SliverFillRemaining(
              hasScrollBody: false,
              child: AppLoadErrorView(onRetry: cubit.retry),
            ),
            SavedListingsStatus.ready when state.items.isEmpty =>
              SliverFillRemaining(
                hasScrollBody: false,
                child: FeedbackView(
                  icon: recent ? AppIcons.clock : AppIcons.favorite,
                  title: recent
                      ? l10n.recentlyViewedEmptyTitle
                      : l10n.emptySavedTitle,
                  message: recent
                      ? l10n.recentlyViewedEmptyBody
                      : l10n.emptySavedDescription,
                ),
              ),
            SavedListingsStatus.ready => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              sliver: AppListingSliverGrid(
                items: state.items,
                itemBuilder: (context, item) => AppListingCard(
                  item: item,
                  onTap: () => _openDetail(context, item),
                  onFavoriteTap: () => cubit.toggleFavorite(item),
                ),
              ),
            ),
          };
          return AppPullToRefresh(
            onRefresh: cubit.refresh,
            child: AppLoadMoreListener(
              onLoadMore: cubit.loadMore,
              child: CustomScrollView(
                scrollCacheExtent: AppScroll.prefetchCacheExtent,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  content,
                  if (state.status == SavedListingsStatus.ready &&
                      state.items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: AppLoadMoreFooter(
                        isLoading: state.isLoadingMore,
                        hasMore: state.hasMore,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
