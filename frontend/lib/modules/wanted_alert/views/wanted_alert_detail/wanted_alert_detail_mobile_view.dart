import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:restore/shared/widgets/search/app_search_section_header.dart';

import '../../bloc/wanted_alert_detail/wanted_alert_detail_cubit.dart';
import '../../bloc/wanted_alert_detail/wanted_alert_detail_state.dart';
import '../../models/wanted_alert_match.dart';
import '../../widgets/wanted_alert_delete_sheet.dart';
import '../../widgets/wanted_alert_match_card.dart';
import '../../widgets/wanted_alert_page_header.dart';
import 'widgets/wanted_alert_detail_summary.dart';
import '../../widgets/wanted_alert_glass_scaffold.dart';

class WantedAlertDetailMobileView extends StatefulWidget {
  const WantedAlertDetailMobileView({super.key});

  @override
  State<WantedAlertDetailMobileView> createState() =>
      _WantedAlertDetailMobileViewState();
}

class _WantedAlertDetailMobileViewState
    extends State<WantedAlertDetailMobileView> {
  static const double _sidePadding = 16;

  void _back() =>
      context.canPop() ? context.pop() : context.go('/wanted-alerts');

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WantedAlertDetailCubit>();
    final keywords = cubit.state.alert?.alert.keywords ?? '';
    if (!await confirmDeleteWantedAlert(context, keywords: keywords)) return;
    final deleted = await cubit.delete();
    if (!mounted) return;
    if (!deleted) {
      TSnackBarHelper.showError(context, message: l10n.wantedAlertDeleteError);
      return;
    }
    TSnackBarHelper.showSuccess(context, message: l10n.wantedAlertDeleted);
    context.canPop() ? context.pop(true) : context.go('/wanted-alerts');
  }

  /// Mở tin khớp; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openListing(WantedAlertMatch match) async {
    final favorite = await context.push<bool>(
      '/listings/${match.listingId}',
      extra: match.item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<WantedAlertDetailCubit>().syncFavorite(
      match.listingId,
      favorite,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WantedAlertDetailCubit>();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<WantedAlertDetailCubit, WantedAlertDetailState>(
      builder: (context, state) {
        final item = state.alert;
        return WantedAlertGlassScaffold(
          estimatedHeaderHeight: 110,
          header: WantedAlertPageHeader(
            title: item?.alert.keywords ?? l10n.wantedAlertTitle,
            subtitle: item == null
                ? null
                : item.matchCount == 0
                ? l10n.wantedAlertWatching
                : l10n.wantedAlertMatchCount(item.matchCount),
            onBack: _back,
            trailing: AppCircleIconButton(
              icon: AppIcons.delete,
              tooltip: l10n.wantedAlertDelete,
              onTap: item == null || state.isDeleting ? null : _delete,
            ),
            bottom: item == null ? null : WantedAlertDetailSummary(item: item),
          ),
          bodyBuilder: (context, topInset) => Stack(
            children: [
              AppPullToRefresh(
                onRefresh: cubit.refresh,
                indicatorTop: topInset + 8,
                child: AppLoadMoreListener(
                  onLoadMore: cubit.loadMore,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: topInset)),
                      SliverToBoxAdapter(
                        child: AppSearchSectionHeader(
                          title: l10n.wantedAlertMatchesTitle,
                        ),
                      ),
                      ..._content(state),
                      SliverToBoxAdapter(child: SizedBox(height: bottom + 16)),
                    ],
                  ),
                ),
              ),
              if (state.isDeleting)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66FFFFFF),
                    child: Center(child: AppLoadingIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _content(WantedAlertDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WantedAlertDetailCubit>();

    switch (state.status) {
      case WantedAlertDetailStatus.loading:
        return [const SliverToBoxAdapter(child: AppListingGridSkeleton())];
      case WantedAlertDetailStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FeedbackView(
              icon: AppIcons.offline,
              title: l10n.wantedAlertLoadErrorTitle,
              message: l10n.wantedAlertLoadErrorBody,
              action: FilledButton(
                onPressed: cubit.retry,
                child: Text(l10n.retry),
              ),
            ),
          ),
        ];
      case WantedAlertDetailStatus.ready:
        break;
    }

    if (state.matches.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedbackView(
            icon: AppIcons.wantedAlert,
            title: l10n.wantedAlertMatchesEmptyTitle,
            message: l10n.wantedAlertMatchesEmptyBody,
          ),
        ),
      ];
    }

    final matches = {for (final match in state.matches) match.listingId: match};
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
        sliver: AppListingSliverGrid(
          items: [for (final match in state.matches) match.item],
          itemBuilder: (_, item) {
            final match = matches[item.listing.id]!;
            return WantedAlertMatchCard(
              match: match,
              onTap: () => _openListing(match),
              onFavoriteTap: () => cubit.toggleFavorite(match),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          isLoading: state.isLoadingMore,
          hasMore: state.hasMore,
          endText: l10n.wantedAlertEndOfList,
        ),
      ),
    ];
  }
}
