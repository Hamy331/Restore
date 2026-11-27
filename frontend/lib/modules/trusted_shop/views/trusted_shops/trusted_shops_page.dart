import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/filter/listing_filter_labels.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/followed_shops/followed_shops_cubit.dart';
import '../../bloc/trusted_shops/trusted_shops_cubit.dart';
import '../../bloc/trusted_shops/trusted_shops_state.dart';
import '../../models/shop_banner_item.dart';
import '../../models/shop_product_item.dart';
import '../../models/trusted_shop_item.dart';
import '../../models/trusted_shops_overview.dart';
import '../../widgets/shop_banner_carousel.dart';
import '../../widgets/shop_verification_badge.dart';
import '../../widgets/shop_verification_sheet.dart';
import '../../widgets/trusted_shop_section_header.dart';
import '../following_shops/following_shops_view.dart';
import '../shop_detail/shop_detail_view.dart';
import 'widgets/followed_shops_section.dart';
import 'widgets/trusted_new_releases.dart';
import 'widgets/trusted_section_bar.dart';
import 'widgets/trusted_shop_carousel.dart';
import 'widgets/trusted_shop_showcase.dart';
import 'widgets/trusted_shops_skeleton.dart';

class TrustedShopsPage extends StatefulWidget {
  /// Shop cần mở ngay khi vào trang ([TrustedShopsView.openShopId])
  final String? openShopId;

  const TrustedShopsPage({super.key, this.openShopId});

  @override
  State<TrustedShopsPage> createState() => _TrustedShopsPageState();
}

class _TrustedShopsPageState extends State<TrustedShopsPage> {
  static const double _sidePadding = 16;
  static const double _sectionGap = 26;

  /// Cỡ khung nội dung trên desktop, cùng cỡ trang chủ / Feeds
  static const double _desktopMaxWidth = AppDimesions.desktopContentWidth;

  final _scrollController = ScrollController();

  /// Vùng cuộn, làm gốc đo vị trí các khu (không phụ thuộc lề của khung ngoài)
  final _scrollKey = GlobalKey();

  /// Đầu mỗi khu, để thanh mục cuộn tới và biết đang xem khu nào
  final _sectionKeys = {
    for (final section in TrustedShopsSection.values) section: GlobalKey(),
  };

  /// Khu đang xem, null khi còn ở phần banner
  TrustedShopsSection? _activeSection;
  bool _activeCheckScheduled = false;

  /// Đầu trang cuộn đi cùng nội dung, chỉ thanh mục được ghim
  static const double _pinnedHeight = TrustedSectionBarDelegate.height;

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
    super.dispose();
  }

  void _onScroll() {
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
    final scroll = _scrollKey.currentContext?.findRenderObject();
    if (target is! RenderBox || scroll is! RenderBox || !target.attached) {
      return null;
    }
    return target.localToGlobal(Offset.zero, ancestor: scroll).dy;
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

  Future<void> _pickSort(BuildContext anchor) async {
    final cubit = context.read<TrustedShopsCubit>();
    final sort = await showListingSortSheet(
      anchor,
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
    context.read<FollowedShopsCubit>().load();
  }

  /// Theo dõi / bỏ theo dõi ở thẻ shop rồi tải lại dải "Shop bạn theo dõi"
  Future<void> _toggleFollow(TrustedShopItem item) async {
    final followed = context.read<FollowedShopsCubit>();
    await context.read<TrustedShopsCubit>().toggleFollow(item);
    await followed.load();
  }

  void _openShopItem(TrustedShopItem item) =>
      _openShop(item.shop.id, item: item);

  /// Banner gắn tin thì mở tin đó, không thì mở trang shop
  void _openBanner(ShopBannerItem banner) {
    final listingId = banner.banner.listingId;
    if (listingId != null) {
      context.push('/listings/$listingId');
      return;
    }
    _openShop(banner.shop.id);
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
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= AppDimesions.desktopWidth;
    final tablet = width >= AppDimesions.mobileWidth;
    // Màn rộng: thêm lề hai bên để nội dung không dính sát mép
    final gutter = desktop
        ? 12.0
        : tablet
        ? 8.0
        : 0.0;

    final title = AppPageTitleRow(
      title: AppLocalizations.of(context)!.trustedShopsTitle,
      subtitle: AppLocalizations.of(context)!.trustedShopsSubtitle,
      onBack: _back,
      trailing: AppCircleIconButton(
        icon: AppIcons.help,
        tooltip: AppLocalizations.of(context)!.shopVerificationSheetTitle,
        onTap: _showVerificationInfo,
      ),
    );

    final scroll = BlocBuilder<TrustedShopsCubit, TrustedShopsState>(
      builder: (context, state) => AppPullToRefresh.inline(
        onRefresh: cubit.refresh,
        builder: (context, refreshIndicator) => AppLoadMoreListener(
          onLoadMore: cubit.loadMore,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: CustomScrollView(
              key: _scrollKey,
              controller: _scrollController,
              // Dựng sẵn các khu phía dưới để thanh mục cuộn tới được
              scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Điện thoại / tablet: tiêu đề cuộn đi cùng nội dung. Desktop:
                // tiêu đề cố định phía trên khung (xem bên dưới).
                if (!desktop)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: title,
                    ),
                  ),
                // Viên loading kéo để làm mới mở ra ngay dưới tiêu đề
                SliverToBoxAdapter(child: refreshIndicator),
                ..._content(state),
                SliverToBoxAdapter(
                  child: SizedBox(height: padding.bottom + 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!desktop) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(bottom: false, child: scroll),
      );
    }

    // Desktop: khối trắng bo góc rộng tối đa 1200px ở giữa như các trang
    // khác, tiêu đề (không có nút ←) cố định, nội dung cuộn bên dưới
    return Material(
      color: AppColors.fill,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _desktopMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    title,
                    Expanded(child: scroll),
                  ],
                ),
              ),
            ),
          ),
        ),
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
            child: AppLoadErrorView(
              title: l10n.trustedShopsLoadErrorTitle,
              onRetry: cubit.retry,
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
          child: LayoutBuilder(
            builder: (context, box) => ShopBannerCarousel(
              banners: overview.banners,
              onTap: _openBanner,
              // Màn rộng: hai banner cạnh nhau, mỗi banner cỡ như điện thoại
              columns: ShopBannerCarousel.columnsFor(box.maxWidth),
            ),
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
      SliverToBoxAdapter(
        child: FollowedShopsSection(
          onShopTap: (shop) => _openShopItem(shop.item),
          onSeeAll: () => context.push(FollowingShopsView.path),
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
              eyebrow: l10n.trustedShopsFamousEyebrow,
              accent: ShopVerificationStyle.official.accent,
              shops: overview.famousShops,
              onShopTap: _openShopItem,
              onFollowTap: _toggleFollow,
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
              eyebrow: l10n.trustedShopsNewShopsEyebrow,
              accent: ShopVerificationStyle.certified.accent,
              shops: overview.newShops,
              onShopTap: _openShopItem,
              onFollowTap: _toggleFollow,
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
            eyebrow: l10n.trustedShopsShowcaseEyebrow,
          ),
        ),
        gap(12),
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final wide = width >= AppDimesions.mobileWidth;
            // Từ ~720px chia 2 cột, hẹp hơn thì mỗi khối một hàng
            final columns = width >= 720 ? 2 : 1;
            Widget block(ShopShowcase showcase, {bool grid = false}) =>
                TrustedShopShowcaseBlock(
                  showcase: showcase,
                  fit: wide,
                  padding: grid
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: _sidePadding),
                  onShopTap: () => _openShopItem(showcase.shop),
                  onListingTap: _openListing,
                  onFavoriteTap: cubit.toggleFavorite,
                );
            if (columns == 1) {
              return SliverList.separated(
                itemCount: overview.showcases.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, index) => block(overview.showcases[index]),
              );
            }
            final rows = (overview.showcases.length / columns).ceil();
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              sliver: SliverList.separated(
                itemCount: rows,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, row) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: 14),
                      Expanded(
                        child: row * columns + c < overview.showcases.length
                            ? block(
                                overview.showcases[row * columns + c],
                                grid: true,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
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
          eyebrow: l10n.trustedShopsAllProductsEyebrow,
          trailing: Builder(
            builder: (anchor) => AppFilterChip(
              label: state.sort.label(l10n),
              hasDropdown: true,
              onTap: () => _pickSort(anchor),
            ),
          ),
        ),
      ),
      gap(12),
      SliverToBoxAdapter(
        child: AppFilterBar(
          children: [
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
