import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/shop_detail/shop_detail_cubit.dart';
import '../../bloc/shop_detail/shop_detail_state.dart';
import '../../widgets/shop_banner_carousel.dart';
import '../../widgets/shop_logo.dart';
import '../../widgets/shop_verification_sheet.dart';
import '../../widgets/trusted_shop_section_header.dart';
import 'widgets/shop_detail_filter_bar.dart';
import 'widgets/shop_detail_profile.dart';
import 'widgets/shop_detail_skeleton.dart';
import 'widgets/shop_detail_top_bar.dart';

class ShopDetailMobileView extends StatefulWidget {
  const ShopDetailMobileView({super.key});

  @override
  State<ShopDetailMobileView> createState() => _ShopDetailMobileViewState();
}

class _ShopDetailMobileViewState extends State<ShopDetailMobileView> {
  static const double _sidePadding = 16;
  static const double _contentRadius = 24;

  final _scrollController = ScrollController();

  /// Đầu khu "Sản phẩm đang bán", bấm banner thì cuộn tới
  final _productsKey = GlobalKey();

  /// Phần đầu đã ghim (đã cuộn), để dải thanh trạng thái đổi màu theo
  final _headerPinned = ValueNotifier(false);
  final _headerKey = GlobalKey();

  /// Trạng thái theo dõi lúc mở trang (hoặc lúc vừa tải xong shop), để trả
  /// kết quả về trang trước nếu người dùng đổi
  bool? _initialFollowing;

  @override
  void initState() {
    super.initState();
    _initialFollowing = context.read<ShopDetailCubit>().state.shop?.isFollowing;
    _scrollController.addListener(_updateHeaderPinned);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerPinned.dispose();
    super.dispose();
  }

  /// Đầu trang đã cuộn khuất thì dải thanh trạng thái đổi sang màu phần ghim
  void _updateHeaderPinned() {
    final headerHeight = _headerKey.currentContext?.size?.height;
    if (headerHeight == null) return;
    _headerPinned.value = _scrollController.offset >= headerHeight;
  }

  bool get _followChanged {
    final following = context.read<ShopDetailCubit>().state.shop?.isFollowing;
    return _initialFollowing != null && following != _initialFollowing;
  }

  /// Đóng trang, kèm trạng thái theo dõi mới nếu đã đổi
  void _close() {
    final following = context.read<ShopDetailCubit>().state.shop?.isFollowing;
    if (!context.canPop()) {
      context.go('/home');
      return;
    }
    context.pop(_followChanged ? following : null);
  }

  void _showCertificate() {
    final shop = context.read<ShopDetailCubit>().state.shop;
    if (shop != null) showShopVerificationSheet(context, shop: shop.shop);
  }

  Future<void> _openFilters() async {
    final cubit = context.read<ShopDetailCubit>();
    final filter = await showListingFilterSheet(
      context,
      filter: cubit.state.filter,
      defaults: ShopDetailState.defaultFilter,
      showCategories: false,
    );
    if (filter != null) cubit.applyFilter(filter);
  }

  Future<void> _pickSort() async {
    final cubit = context.read<ShopDetailCubit>();
    final sort = await showListingSortSheet(
      context,
      selected: cubit.state.filter.sort,
      options: ShopDetailState.sortOptions,
    );
    if (sort != null) cubit.setSort(sort);
  }

  /// Cuộn tới khu sản phẩm (bấm banner sự kiện của chính shop này)
  void _scrollToProducts() {
    final target = _productsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
      // Chừa chỗ cho hàng tên shop đang ghim
      alignment: 0.08,
    );
  }

  /// Mở trang chi tiết; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openListing(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<ShopDetailCubit>().syncFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShopDetailCubit>();
    final padding = MediaQuery.paddingOf(context);

    return BlocBuilder<ShopDetailCubit, ShopDetailState>(
      builder: (context, state) {
        // Mở bằng đường dẫn / banner thì lấy trạng thái theo dõi lúc vừa tải
        _initialFollowing ??= state.shop?.isFollowing;
        return PopScope(
          // Trạng thái theo dõi đã đổi thì tự đóng trang để trả kết quả về
          canPop: !_followChanged,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close();
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: Column(
              children: [
                // Thanh trạng thái cùng màu phần đầu, chuyển trắng khi đã cuộn
                ValueListenableBuilder<bool>(
                  valueListenable: _headerPinned,
                  builder: (context, pinned, _) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: padding.top,
                    width: double.infinity,
                    color: pinned
                        ? AppPinnedHeaderSurface.pinnedColor
                        : AppHeaderPalette.top,
                  ),
                ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: AppPullToRefresh.inline(
                      onRefresh: cubit.refresh,
                      builder: (context, refreshIndicator) =>
                          AppLoadMoreListener(
                            onLoadMore: cubit.loadMore,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: ShopDetailTopBar(
                                    key: _headerKey,
                                    shop: state.shop?.shop,
                                    onBack: _close,
                                    onCertificateTap: _showCertificate,
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: ColoredBox(
                                    color: AppHeaderPalette.bottom,
                                    child: refreshIndicator,
                                  ),
                                ),
                                // Mép trên bo cong của phần nội dung trắng
                                SliverToBoxAdapter(
                                  child: ColoredBox(
                                    color: AppHeaderPalette.bottom,
                                    child: Container(
                                      height: _contentRadius,
                                      decoration: const BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(_contentRadius),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                ..._content(state),
                                SliverToBoxAdapter(
                                  child: SizedBox(height: padding.bottom + 16),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _content(ShopDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ShopDetailCubit>();
    final shop = state.shop;

    // Chưa có thông tin shop mà tải lỗi thì cả trang báo lỗi
    if (shop == null && state.status == ShopDetailStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedbackView(
            icon: AppIcons.offline,
            title: l10n.shopDetailLoadErrorTitle,
            message: l10n.shopDetailLoadErrorBody,
            action: FilledButton(
              onPressed: cubit.retry,
              child: Text(l10n.retry),
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: shop == null
            ? const ShopDetailProfileSkeleton()
            : ShopDetailProfile(
                item: shop,
                onFollowTap: cubit.toggleFollow,
                onCertificateTap: _showCertificate,
              ),
      ),
      if (shop != null && state.banners.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: TrustedShopSectionHeader(
            title: l10n.shopDetailEventsTitle,
            subtitle: l10n.shopDetailEventsSubtitle,
            icon: AppIcons.event,
            iconColor: ShopLogo.accentOf(shop.shop),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: ShopBannerCarousel(
            banners: state.banners,
            onTap: (_) => _scrollToProducts(),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
      SliverToBoxAdapter(
        child: TrustedShopSectionHeader(
          key: _productsKey,
          title: l10n.shopDetailProductsTitle,
          subtitle: shop == null
              ? null
              : l10n.shopListingCount(shop.shop.listingCount),
          icon: AppIcons.listings,
          iconColor: shop == null
              ? AppColors.primaryDark
              : ShopLogo.accentOf(shop.shop),
        ),
      ),
      // Hàng lọc ghim trên cùng khi cuộn tới phần sản phẩm
      SliverPersistentHeader(
        pinned: true,
        delegate: ShopDetailFilterBarDelegate(
          filterBar: AppListingFilterBar(
            filter: state.filter,
            defaults: ShopDetailState.defaultFilter,
            onFiltersTap: _openFilters,
            onDealToggle: cubit.toggleDeal,
            onSortTap: _pickSort,
            onClearTap: cubit.clearFilters,
          ),
        ),
      ),
      ..._products(state),
    ];
  }

  List<Widget> _products(ShopDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ShopDetailCubit>();

    switch (state.status) {
      case ShopDetailStatus.loading:
        return [const SliverToBoxAdapter(child: AppListingGridSkeleton())];
      case ShopDetailStatus.failure:
        return [
          SliverToBoxAdapter(
            child: FeedbackView(
              icon: AppIcons.offline,
              title: l10n.shopDetailLoadErrorTitle,
              message: l10n.shopDetailLoadErrorBody,
              action: FilledButton(
                onPressed: cubit.retry,
                child: Text(l10n.retry),
              ),
            ),
          ),
        ];
      case ShopDetailStatus.ready:
        break;
    }

    if (state.items.isEmpty) {
      final filtered = state.hasActiveFilters;
      return [
        SliverToBoxAdapter(
          child: FeedbackView(
            icon: filtered ? AppIcons.searchEmpty : AppIcons.shop,
            title: filtered
                ? l10n.categoryDetailFilteredEmptyTitle
                : l10n.shopDetailEmptyTitle,
            message: filtered
                ? l10n.categoryDetailFilteredEmptyBody
                : l10n.shopDetailEmptyBody,
            action: filtered
                ? OutlinedButton(
                    onPressed: cubit.clearFilters,
                    child: Text(l10n.listingFilterReset),
                  )
                : null,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
        sliver: AppListingSliverGrid(
          items: state.items,
          itemBuilder: (_, item) => AppListingCard(
            item: item,
            onTap: () => _openListing(item),
            onFavoriteTap: () => cubit.toggleFavorite(item),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          isLoading: state.isLoadingMore,
          hasMore: state.hasMore,
          endText: l10n.shopDetailEndOfList,
        ),
      ),
    ];
  }
}
