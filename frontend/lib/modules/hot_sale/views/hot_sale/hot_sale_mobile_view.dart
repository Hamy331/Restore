import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/hot_sale_cubit.dart';
import '../../bloc/hot_sale_state.dart';

class HotSaleMobileView extends StatelessWidget {
  const HotSaleMobileView({super.key});

  static const double _sidePadding = 16;

  Future<void> _openDetail(BuildContext context, ListingCardItem item) async {
    final cubit = context.read<HotSaleCubit>();
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
    final cubit = context.read<HotSaleCubit>();
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
        title: Semantics(
          label: l10n.hotSaleTitle,
          child: Image.asset(
            AppImages.coreImages.hotSale,
            height: 38,
            errorBuilder: (_, _, _) => Text(l10n.hotSaleTitle),
          ),
        ),
      ),
      body: BlocBuilder<HotSaleCubit, HotSaleState>(
        builder: (context, state) {
          final Widget content = switch (state.status) {
            HotSaleStatus.loading => const SliverToBoxAdapter(
              child: AppListingGridSkeleton(),
            ),
            HotSaleStatus.failure => SliverFillRemaining(
              hasScrollBody: false,
              child: FeedbackView(
                icon: AppIcons.offline,
                title: l10n.hotSaleLoadError,
                message: l10n.categoryDetailLoadErrorBody,
                action: FilledButton(
                  onPressed: cubit.retry,
                  child: Text(l10n.retry),
                ),
              ),
            ),
            HotSaleStatus.ready when state.items.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: FeedbackView(
                icon: AppIcons.hot,
                title: l10n.hotSaleEmptyTitle,
                message: l10n.hotSaleEmptyBody,
              ),
            ),
            HotSaleStatus.ready => SliverPadding(
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
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _sidePadding,
                        4,
                        _sidePadding,
                        14,
                      ),
                      child: Text(
                        l10n.hotSaleSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  content,
                  if (state.status == HotSaleStatus.ready &&
                      state.items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: AppLoadMoreFooter(
                        isLoading: state.isLoadingMore,
                        hasMore: state.hasMore,
                        endText: l10n.hotSaleEnd,
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
