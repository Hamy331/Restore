import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/filter/listing_filter_labels.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/trusted_shops/trusted_shops_cubit.dart';
import '../../bloc/trusted_shops/trusted_shops_state.dart';
import '../../models/shop_banner_item.dart';
import '../../models/shop_product_item.dart';
import '../../models/trusted_shop_item.dart';
import '../../widgets/shop_banner_carousel.dart';
import '../../widgets/shop_verification_badge.dart';
import '../../widgets/shop_verification_sheet.dart';
import '../../widgets/trusted_shop_section_header.dart';
import '../shop_detail/shop_detail_view.dart';
import 'widgets/trusted_deals_section.dart';
import 'widgets/trusted_new_releases.dart';
import 'widgets/trusted_section_bar.dart';
import 'widgets/trusted_shop_carousel.dart';
import 'widgets/trusted_shop_showcase.dart';
import 'widgets/trusted_shops_header.dart';
import 'widgets/trusted_shops_skeleton.dart';

class TrustedShopsMobileView extends StatefulWidget {
  /// Shop cần mở ngay khi vào trang ([TrustedShopsView.openShopId])
  final String? openShopId;

  const TrustedShopsMobileView({super.key, this.openShopId});

  @override
  State<TrustedShopsMobileView> createState() => _TrustedShopsMobileViewState();
}

class _TrustedShopsMobileViewState extends State<TrustedShopsMobileView> {
  static const double _sidePadding = 16;
  static const double _contentRadius = 24;
  static const double _sectionGap = 26;

  final _scrollController = ScrollController();

  /// Đầu mỗi khu, để thanh mục cuộn tới và biết đang xem khu nào
  final _sectionKeys = {
    for (final section in TrustedShopsSection.values) section: GlobalKey(),
  };

  /// Khu đang xem, null khi còn ở phần banner
  TrustedShopsSection? _activeSection;
  bool _activeCheckScheduled = false;

  /// Phần đầu đã ghim (đã cuộn), để dải thanh trạng thái đổi màu theo
  final _headerPinned = ValueNotifier(false);

  /// Đầu trang cuộn đi cùng nội dung, chỉ thanh mục được ghim
  static const double _pinnedHeight = TrustedSectionBarDelegate.height;

  final _headerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final shopId = widget.openShopId;
    if (shopId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openShop(shopId);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerPinned.dispose();
    super.dispose();
  }

  void _onScroll() {
    final headerHeight = _headerKey.currentContext?.size?.height;
    if (headerHeight != null) {
      _headerPinned.value = _scrollController.offset >= headerHeight;
    }
    // Vị trí các khu chỉ đúng sau khi khung hình mới đã dựng xong
    if (_activeCheckScheduled) return;
    _activeCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeCheckScheduled = false;
      if (mounted && _scrollController.hasClients) _updateActiveSection();
    });
  }

  /// Khoảng cách từ đầu vùng cuộn tới đầu khu [section], null khi khu không
  /// có trên trang
  double? _sectionTop(TrustedShopsSection section) {
    final target = _sectionKeys[section]?.currentContext?.findRenderObject();
    final page = context.findRenderObject();
    if (target is! RenderBox || page is! RenderBox || !target.attached) {
      return null;
    }
    return target.localToGlobal(Offset.zero, ancestor: page).dy -
        MediaQuery.paddingOf(context).top;
  }

  /// Khu đang xem là khu cuối cùng đã cuộn tới sát dưới phần ghim. Đã cuộn
  /// hết trang thì lấy khu cuối còn thấy trên màn hình, vì khu ngắn ở cuối
  /// không bao giờ lên tới phần ghim.
  void _updateActiveSection() {
    final position = _scrollController.position;
    final atEnd = position.pixels >= position.maxScrollExtent - 1;
    final limit = atEnd ? position.viewportDimension : _pinnedHeight + 24;
    TrustedShopsSection? active;
    for (final section in TrustedShopsSection.values) {
      final top = _sectionTop(section);
      if (top != null && top <= limit) active = section;
    }
    if (active != _activeSection) setState(() => _activeSection = active);
  }

  /// Cuộn sao cho đầu khu [section] nằm ngay dưới phần ghim. Phần cuối trang
  /// dựng dần nên lúc bắt đầu cuộn có thể chưa đủ dài; cuộn xong mà còn lệch
  /// thì chỉnh thêm một lần.
  Future<void> _scrollToSection(
    TrustedShopsSection section, {
    bool retry = true,
  }) async {
    final top = _sectionTop(section);
    if (top == null || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final offset = (position.pixels + top - _pinnedHeight - 8).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if ((offset - position.pixels).abs() < 1) return;
    await _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
    // Đợi khung hình kế để vị trí các khu được đo lại theo chỗ cuộn mới
    await WidgetsBinding.instance.endOfFrame;
    if (retry && mounted) await _scrollToSection(section, retry: false);
  }

  void _back() => context.canPop() ? context.pop() : context.go('/home');

  void _showVerificationInfo() => showShopVerificationSheet(context);

  Future<void> _pickSort() async {
    final cubit = context.read<TrustedShopsCubit>();
    final sort = await showListingSortSheet(
      context,
      selected: cubit.state.sort,
      options: TrustedShopsState.sortOptions,
    );
    if (sort != null) cubit.setSort(sort);
  }

  /// Mở trang shop; quay lại mà trạng thái theo dõi đã đổi thì cập nhật thẻ.
  /// Mở từ banner thì chưa có [item], trang shop tự tải thông tin.
  Future<void> _openShop(String id, {TrustedShopItem? item}) async {
    final following = await context.push<bool>(
      ShopDetailView.location(id),
      extra: item,
    );
    if (following == null || !mounted) return;
    context.read<TrustedShopsCubit>().syncFollowing(id, following);
  }

  void _openShopItem(TrustedShopItem item) =>
      _openShop(item.shop.id, item: item);

  void _openBanner(ShopBannerItem banner) => _openShop(banner.shop.id);

  /// Bật lọc "Đang giảm giá" rồi cuộn tới lưới sản phẩm
  void _showAllDeals() {
    context.read<TrustedShopsCubit>().setOnSale(true);
    _scrollToSection(TrustedShopsSection.allProducts);
  }

  /// Mở trang chi tiết; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openListing(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<TrustedShopsCubit>().syncFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrustedShopsCubit>();
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
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
              child: BlocBuilder<TrustedShopsCubit, TrustedShopsState>(
                builder: (context, state) => AppPullToRefresh.inline(
                  onRefresh: cubit.refresh,
                  builder: (context, refreshIndicator) => AppLoadMoreListener(
                    onLoadMore: cubit.loadMore,
                    child: CustomScrollView(
                      controller: _scrollController,
                      // Dựng sẵn các khu phía dưới để thanh mục cuộn tới được
                      cacheExtent: 3000,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: TrustedShopsHeader(
                            key: _headerKey,
                            onBack: _back,
                            onInfoTap: _showVerificationInfo,
                          ),
                        ),
                        // Viên loading kéo để làm mới mở ra ngay dưới phần ghim
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
          ),
        ],
      ),
    );
  }

  List<Widget> _content(TrustedShopsState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TrustedShopsCubit>();

    switch (state.status) {
      case TrustedShopsStatus.loading:
        return [const SliverToBoxAdapter(child: TrustedShopsSkeleton())];
      case TrustedShopsStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FeedbackView(
              icon: AppIcons.offline,
              title: l10n.trustedShopsLoadErrorTitle,
              message: l10n.trustedShopsLoadErrorBody,
              action: FilledButton(
                onPressed: cubit.retry,
                child: Text(l10n.retry),
              ),
            ),
          ),
        ];
      case TrustedShopsStatus.ready:
        break;
    }

    final overview = state.overview;
    if (overview.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedbackView(
            icon: AppIcons.shop,
            title: l10n.trustedShopsEmptyTitle,
            message: l10n.trustedShopsEmptyBody,
          ),
        ),
      ];
    }

    Widget gap([double height = _sectionGap]) =>
        SliverToBoxAdapter(child: SizedBox(height: height));

    // Các khu đang có nội dung, theo thứ tự trên trang
    final sections = [
      if (overview.famousShops.isNotEmpty) TrustedShopsSection.famous,
      if (overview.deals.isNotEmpty) TrustedShopsSection.deals,
      if (overview.newReleases.isNotEmpty) TrustedShopsSection.newReleases,
      if (overview.newShops.isNotEmpty) TrustedShopsSection.newShops,
      if (overview.showcases.isNotEmpty) TrustedShopsSection.showcases,
      TrustedShopsSection.allProducts,
    ];
    Widget keyed(TrustedShopsSection section, Widget child) =>
        KeyedSubtree(key: _sectionKeys[section], child: child);

    return [
      if (overview.banners.isNotEmpty)
        SliverToBoxAdapter(
          child: ShopBannerCarousel(
            banners: overview.banners,
            onTap: _openBanner,
          ),
        ),
      SliverPersistentHeader(
        pinned: true,
        delegate: TrustedSectionBarDelegate(
          sections: sections,
          active: _activeSection,
          onTap: _scrollToSection,
        ),
      ),
      if (overview.famousShops.isNotEmpty) ...[
        gap(8),
        SliverToBoxAdapter(
          child: keyed(
            TrustedShopsSection.famous,
            TrustedShopCarousel(
              title: l10n.trustedShopsFamousTitle,
              subtitle: l10n.trustedShopsFamousSubtitle,
              icon: AppIcons.brand,
              accent: ShopVerificationStyle.official.accent,
              shops: overview.famousShops,
              onShopTap: _openShopItem,
              onFollowTap: cubit.toggleFollow,
            ),
          ),
        ),
      ],
      if (overview.deals.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: keyed(
            TrustedShopsSection.deals,
            TrustedDealsSection(
              deals: overview.deals,
              onListingTap: _openListing,
              onFavoriteTap: cubit.toggleFavorite,
              onSeeAll: _showAllDeals,
            ),
          ),
        ),
      ],
      if (overview.newReleases.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: keyed(
            TrustedShopsSection.newReleases,
            TrustedNewReleases(
              products: overview.newReleases,
              onProductTap: (product) => _openListing(product.item),
              onFavoriteTap: (ShopProductItem product) =>
                  cubit.toggleFavorite(product.item),
            ),
          ),
        ),
      ],
      if (overview.newShops.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: keyed(
            TrustedShopsSection.newShops,
            TrustedShopCarousel(
              title: l10n.trustedShopsNewShopsTitle,
              subtitle: l10n.trustedShopsNewShopsSubtitle,
              icon: AppIcons.sparkle,
              accent: ShopVerificationStyle.certified.accent,
              shops: overview.newShops,
              onShopTap: _openShopItem,
              onFollowTap: cubit.toggleFollow,
            ),
          ),
        ),
      ],
      if (overview.showcases.isNotEmpty) ...[
        gap(),
        SliverToBoxAdapter(
          child: TrustedShopSectionHeader(
            key: _sectionKeys[TrustedShopsSection.showcases],
            title: l10n.trustedShopsShowcaseTitle,
            subtitle: l10n.trustedShopsShowcaseSubtitle,
            icon: AppIcons.shop,
          ),
        ),
        gap(12),
        SliverList.separated(
          itemCount: overview.showcases.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, index) {
            final showcase = overview.showcases[index];
            return TrustedShopShowcaseBlock(
              showcase: showcase,
              onShopTap: () => _openShopItem(showcase.shop),
              onListingTap: _openListing,
              onFavoriteTap: cubit.toggleFavorite,
            );
          },
        ),
      ],
      gap(),
      SliverToBoxAdapter(
        child: TrustedShopSectionHeader(
          key: _sectionKeys[TrustedShopsSection.allProducts],
          title: l10n.trustedShopsAllProductsTitle,
          subtitle: l10n.trustedShopsAllProductsSubtitle,
          icon: AppIcons.listings,
          trailing: AppFilterChip(
            label: state.sort.label(l10n),
            hasDropdown: true,
            onTap: _pickSort,
          ),
        ),
      ),
      gap(12),
      SliverToBoxAdapter(
        child: AppFilterBar(
          children: [
            AppFilterChip(
              label: l10n.trustedShopsOnSaleFilter,
              icon: AppIcons.sale,
              selected: state.onSale,
              onTap: () => cubit.setOnSale(!state.onSale),
            ),
            AppFilterChip(
              label: l10n.trustedShopsAllCategories,
              icon: AppIcons.category,
              selected: state.categoryId == null,
              onTap: () => cubit.selectCategory(null),
            ),
            for (final category in overview.categories)
              AppFilterChip(
                label: category.name.of(context),
                icon: AppIcons.forCategory(category.iconKey),
                selected: category.id == state.categoryId,
                onTap: () => cubit.selectCategory(category.id),
              ),
          ],
        ),
      ),
      gap(12),
      if (state.isLoadingProducts)
        const SliverToBoxAdapter(child: AppListingGridSkeleton())
      else if (state.products.isEmpty)
        SliverToBoxAdapter(
          child: FeedbackView(
            icon: AppIcons.searchEmpty,
            title: l10n.categoryDetailFilteredEmptyTitle,
            message: l10n.categoryDetailFilteredEmptyBody,
          ),
        )
      else ...[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
          sliver: AppListingSliverGrid(
            items: state.products,
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
            endText: l10n.trustedShopsEndOfList,
          ),
        ),
      ],
    ];
  }
}
