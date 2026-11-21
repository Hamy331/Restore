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

/// Route `/saved`: tin người dùng đã lưu (Tài khoản → Đã lưu)
class SavedListingsView extends StatelessWidget {
  const SavedListingsView({super.key, this.repository});

  /// Thay nguồn dữ liệu khi test
  final SavedListingsRepository? repository;

  static const String path = '/saved';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        SavedListingsCubit(repository: repository ?? SavedListingsRepository())
          ..start(),
    child: const TResponsiveLayout(mobile: _SavedListingsBody()),
  );
}

class _SavedListingsBody extends StatelessWidget {
  const _SavedListingsBody();

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
          l10n.savedListings,
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
                  icon: AppIcons.favorite,
                  title: l10n.emptySavedTitle,
                  message: l10n.emptySavedDescription,
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
