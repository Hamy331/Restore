import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:restore/modules/following/views/following_hub/following_hub_view.dart';
import 'package:restore/modules/hot_sale/views/hot_sale/hot_sale_view.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/shared/widgets/filter/area_filter_panel.dart';
import 'package:restore/modules/trusted_shop/views/trusted_shops/trusted_shops_view.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alerts/wanted_alerts_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/home_cubit.dart';
import '../../bloc/home_state.dart';
import '../../models/home_banner.dart';
import '../../models/home_listing_filter.dart';
import '../../models/home_quick_action.dart';
import 'widgets/home_category_photo_grid.dart';
import 'widgets/home_quick_actions.dart';

/// Trang chủ trên web desktop (bố cục kiểu Shopee): banner lớn + 2 banner
/// phụ, 4 lối tắt, lưới danh mục, Hot sale, rồi lưới tin theo tab. Nội dung
/// 1200px ở giữa, hai bên để trống, footer ở cuối trang.
class HomeDesktopView extends StatefulWidget {
  const HomeDesktopView({super.key});

  @override
  State<HomeDesktopView> createState() => _HomeDesktopViewState();
}

class _HomeDesktopViewState extends State<HomeDesktopView> {
  static const double _gap = 20;

  HomeCubit get _cubit => context.read<HomeCubit>();

  Future<void> _openDetail(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    _cubit.syncFavorite(id, favorite);
  }

  void _toggleFavorite(ListingCardItem item) {
    if (!context.isSignedIn) {
      context.go(loginPath(from: '/home'));
      return;
    }
    _cubit.toggleFavorite(item);
  }

  void _openCategory(CategoryModel category) =>
      context.push(CategoryDetailView.location(category.id), extra: category);

  void _onQuickAction(HomeQuickAction action) => context.push(
    switch (action) {
      HomeQuickAction.nearby => '/nearby',
      HomeQuickAction.wantedAlert => WantedAlertsView.path,
      HomeQuickAction.trustedShops => TrustedShopsView.path,
      HomeQuickAction.following => FollowingHubView.path,
    },
  );

  Future<void> _pickArea() async {
    final userArea = context.read<UserAreaCubit>();
    final result = await showAreaPicker(
      context,
      current: userArea.state.area,
    );
    if (result == null) return;
    if (result.nationwide) {
      userArea.selectNationwide();
    } else if (result.area case final area?) {
      userArea.select(area);
    } else if (result.useMyLocation) {
      await userArea.locate();
    }
  }

  Widget _card(ListingCardItem item, {bool nearby = false}) => AppListingCard(
    item: item,
    showDistance: nearby,
    onTap: () => _openDetail(item),
    onFavoriteTap: () => _toggleFavorite(item),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => DesktopPage(
        onEndReached: state.status == HomeStatus.ready ? _cubit.loadMore : null,
        slivers: switch (state.status) {
          HomeStatus.loading => [
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 480,
                child: Center(child: AppLoadingIndicator()),
              ),
            ),
          ],
          HomeStatus.failure => [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 480,
                child: FeedbackView(
                  icon: AppIcons.offline,
                  title: l10n.homeLoadErrorTitle,
                  message: l10n.homeLoadErrorBody,
                  action: FilledButton(
                    onPressed: _cubit.load,
                    child: Text(l10n.retry),
                  ),
                ),
              ),
            ),
          ],
          HomeStatus.ready => _content(state, l10n),
        },
      ),
    );
  }

  List<Widget> _content(HomeState state, AppLocalizations l10n) {
    final area = context.watch<UserAreaCubit>().state;
    final nearby = state.filter == HomeListingFilter.nearby;
    return [
      if (state.banners.isNotEmpty)
        SliverToBoxAdapter(
          child: _Hero(
            banners: state.banners,
            onTap: (banner) {
              final route = banner.route;
              if (route != null) context.push(route);
            },
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: _gap),
          child: HomeQuickActions(
            onTap: _onQuickAction,
            perRow: 4,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      if (state.categories.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: _gap),
            child: DesktopBox(
              title: Localizations.localeOf(context).languageCode == 'vi'
                  ? 'Danh mục'
                  : 'Categories',
              padding: EdgeInsets.zero,
              child: HomeCategoryPhotoGrid(
                categories: state.categories,
                onTap: _openCategory,
                onHotSaleTap: () => context.push(HotSaleView.path),
              ),
            ),
          ),
        ),
      if (state.recommended.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: _gap),
            child: DesktopBox(
              title: l10n.hotSaleTitle.toUpperCase(),
              titleIcon: Image.asset(
                AppImages.coreImages.hotFlame,
                width: 24,
                height: 24,
              ),
              trailing: DesktopSeeAll(
                label: l10n.homeSeeAll,
                onTap: () => context.push(HotSaleView.path),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const columns = 6;
                  const spacing = 12.0;
                  final width =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final item in state.recommended.take(columns))
                        SizedBox(
                          width: width,
                          height: AppListingCard.heightFor(width),
                          child: _card(item),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      // Tab Dành cho bạn / Gần bạn / Mới nhất (giống "Gợi ý hôm nay")
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: _gap),
          child: _FeedTabs(
            selected: state.filter,
            onSelect: (filter) => _cubit.selectFeed(filter, area.origin),
          ),
        ),
      ),
      DecoratedSliver(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            left: BorderSide(color: AppColors.border),
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        sliver: SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverMainAxisGroup(
            slivers: [
              if (nearby && area.origin == null)
                SliverToBoxAdapter(
                  child: Center(
                    child: TextButton(
                      onPressed: area.isLocating ? null : _pickArea,
                      child: Text(
                        area.isLocating
                            ? l10n.nearbyLocating
                            : l10n.selectAddressHint,
                      ),
                    ),
                  ),
                )
              else if (state.latest.isEmpty &&
                  !state.isLoadingMore &&
                  !state.feedFailed)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      nearby ? l10n.nearbyEmptyTitle : l10n.homeLatestEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                AppListingSliverGrid(
                  items: state.latest,
                  maxCardWidth: 190,
                  itemBuilder: (_, item) => _card(item, nearby: nearby),
                ),
              if (state.feedFailed)
                SliverToBoxAdapter(
                  child: Center(
                    child: TextButton(
                      onPressed: () => _cubit.loadMore(retry: true),
                      child: Text(l10n.retry),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: AppLoadMoreFooter(
                  isLoading: state.isLoadingMore,
                  hasMore: state.hasMoreLatest,
                  endText: state.latest.isEmpty ? null : l10n.homeEndOfList,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Banner lớn tự chuyển bên trái, hai banner phụ bên phải
class _Hero extends StatefulWidget {
  const _Hero({required this.banners, required this.onTap});
  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onTap;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  static const double _height = 300;
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  /// Banner phụ bên phải lấy từ cuối danh sách khi có từ 3 banner
  List<HomeBanner> get _side =>
      widget.banners.length >= 3 ? widget.banners.sublist(widget.banners.length - 2) : const [];

  List<HomeBanner> get _main => widget.banners.length >= 3
      ? widget.banners.sublist(0, widget.banners.length - 2)
      : widget.banners;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _go(_page + 1));
  }

  void _go(int page) {
    final count = _main.length;
    if (count < 2 || !_controller.hasClients) return;
    _controller.animateToPage(
      page % count,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _banner(HomeBanner banner) {
    final url = banner.imageUrl;
    return Material(
      color: AppColors.cream,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: banner.route == null ? null : () => widget.onTap(banner),
        child: url == null
            ? const Center(
                child: Icon(AppIcons.image, color: AppColors.textSecondary),
              )
            : AppLocalImage(path: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final main = _main;
    final side = _side;
    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: main.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (_, index) => _banner(main[index]),
                ),
                if (main.length > 1) ...[
                  Positioned(
                    left: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Arrow(
                        icon: Icons.chevron_left,
                        onTap: () => _go(_page - 1 + main.length),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Arrow(
                        icon: Icons.chevron_right,
                        onTap: () => _go(_page + 1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < main.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i == _page
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: .6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (side.isNotEmpty) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 392,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _banner(side[0])),
                  const SizedBox(height: 8),
                  Expanded(child: _banner(side[1])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .88),
    shape: const CircleBorder(),
    elevation: 2,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 22)),
    ),
  );
}

class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selected, required this.onSelect});
  final HomeListingFilter selected;
  final ValueChanged<HomeListingFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (filter, label) in [
            (HomeListingFilter.forYou, l10n.feedForYou),
            (HomeListingFilter.nearby, l10n.homeQuickNearby),
            (HomeListingFilter.newest, l10n.listingSortNewest),
          ])
            InkWell(
              onTap: () => onSelect(filter),
              child: Container(
                padding: const EdgeInsets.fromLTRB(34, 16, 34, 13),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: filter == selected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: filter == selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: filter == selected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
