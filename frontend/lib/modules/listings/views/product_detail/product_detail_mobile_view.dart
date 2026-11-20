import 'package:restore/modules/content/views/community_content_view.dart'
    show reportListing;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/animations/fade_slide_in.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/product_detail/product_detail_cubit.dart';
import '../../bloc/product_detail/product_detail_state.dart';
import '../../models/product_detail.dart';
import '../../../boost/views/boost_listing/boost_listing_view.dart';
import '../edit_listing/edit_listing_view.dart';
import 'widgets/product_detail_attributes.dart';
import 'widgets/product_detail_bottom_bar.dart';
import 'widgets/product_detail_description.dart';
import 'widgets/product_detail_offer_sheet.dart';
import 'widgets/product_detail_header.dart';
import 'widgets/product_chat_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'widgets/product_detail_safety_tips.dart';
import 'widgets/product_detail_seller_card.dart';
import 'widgets/product_similar_listings.dart';
import 'widgets/product_detail_skeleton.dart';
import 'widgets/product_detail_summary.dart';

/// Trang chi tiết sản phẩm cho người mua: ảnh vuốt / phóng to, thông tin,
/// người bán và thanh hành động cố định (nhắn tin, trả giá, mua ngay).
///
/// Tin tự làm mới khi đang xem (và khi quay lại ứng dụng, khi kéo xuống),
/// báo cho người mua nếu người khác vừa mua hoặc người bán vừa sửa tin.
///
/// Khi đóng trang, nếu trạng thái "Lưu tin" đã đổi thì trả về giá trị mới
/// để trang trước cập nhật thẻ tin.
class ProductDetailMobileView extends StatefulWidget {
  const ProductDetailMobileView({super.key});

  @override
  State<ProductDetailMobileView> createState() =>
      _ProductDetailMobileViewState();
}

class _ProductDetailMobileViewState extends State<ProductDetailMobileView> {
  final _scrollController = ScrollController();

  /// Đã cuộn qua ảnh để hiện tiêu đề trên thanh trên cùng
  final _collapsed = ValueNotifier(false);

  late final AppLifecycleListener _lifecycle;

  ProductDetailCubit get _cubit => context.read<ProductDetailCubit>();
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCollapsed);
    _lifecycle = AppLifecycleListener(
      onHide: () => _cubit.pauseLiveUpdates(),
      onShow: () => _cubit.resumeLiveUpdates(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scrollController.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  void _updateCollapsed() {
    final threshold =
        ProductDetailHeader.galleryHeight(context) -
        MediaQuery.paddingOf(context).top -
        kToolbarHeight * 2;
    _collapsed.value = _scrollController.offset > threshold;
  }

  void _close() {
    final state = _cubit.state;
    context.pop(state.favoriteChanged ? state.detail!.isFavorite : null);
  }

  /// Chủ tin mở trang quảng bá (đẩy tin 24 giờ, Hot sale bằng xu)
  Future<void> _onPromote(ProductDetail detail) async {
    if (!detail.isAvailable) {
      TSnackBarHelper.showInfo(
        context,
        message: _l10n.boostUnavailableDescription,
      );
      return;
    }
    await context.push<bool>(BoostListingView.location(detail.listing.id));
  }

  /// Sửa tin của mình; quay lại thì tải lại (tin đã duyệt vẫn hiện bản cũ
  /// tới khi bản sửa được duyệt)
  Future<void> _onEdit(ProductDetail detail) async {
    await context.push<bool>(EditListingView.location(detail.listing.id));
    if (mounted) await _cubit.refresh();
  }

  bool _signedIn() {
    if (context.isSignedIn) return true;
    context.go(loginPath(from: '/listings/${_cubit.listingId}'));
    return false;
  }

  Future<void> _onChat(ProductDetail detail) async {
    if (!_signedIn()) return;
    final id = await showProductChatSheet(context, detail);
    if (mounted && id != null) openListingConversation(context, id);
  }

  Future<void> _call(String number) async {
    try {
      if (await launchUrl(
        Uri(scheme: 'tel', path: number),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      TSnackBarHelper.showInfo(
        context,
        message: '${_l10n.listingCallUnavailable} $number',
      );
    }
  }

  void _save() {
    if (_signedIn()) _cubit.toggleFavorite();
  }

  void _onChanged(BuildContext context, ProductDetailState state) {
    final change = state.lastChange;
    final listing = state.detail?.listing;
    if (change == null || listing == null) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String money(int price) =>
        CurrencyFormatter.formatVnd(price, locale: locale);

    final message = switch (change.kind) {
      ProductDetailChangeKind.unavailable => _l10n.productLiveUnavailable(
        listing.status.label(_l10n).toLowerCase(),
      ),
      ProductDetailChangeKind.available => _l10n.productLiveAvailable,
      ProductDetailChangeKind.price
          when change.previousPrice != null && listing.price != null =>
        _l10n.productLivePrice(
          money(change.previousPrice!),
          money(listing.price!),
        ),
      ProductDetailChangeKind.price => _l10n.productLivePriceGeneric,
      ProductDetailChangeKind.info => _l10n.productLiveInfo,
    };

    final title = _l10n.productLiveTitle;
    change.kind == ProductDetailChangeKind.unavailable
        ? TSnackBarHelper.showWarning(context, title: title, message: message)
        : TSnackBarHelper.showInfo(context, title: title, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listenWhen: (previous, current) =>
          previous.changeCount != current.changeCount,
      listener: _onChanged,
      builder: (context, state) {
        final detail = state.detail;
        final phone = detail?.seller.phone?.replaceAll(RegExp(r'[\s().-]'), '');
        return PopScope(
          // Trạng thái lưu tin đã đổi thì tự đóng trang để trả kết quả về
          canPop: !state.favoriteChanged,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            extendBody: true,
            // Builder để đọc padding đáy đã cộng chiều cao thanh hành động
            body: Builder(
              builder: (bodyContext) => AppPullToRefresh(
                // Viên loading hiện ngay dưới hàng nút quay lại / lưu tin
                indicatorTop:
                    MediaQuery.paddingOf(context).top + kToolbarHeight,
                onRefresh: _cubit.refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _collapsed,
                      builder: (context, collapsed, _) => ProductDetailHeader(
                        images: detail?.listing.images ?? state.preview?.images,
                        heroTag: 'product-${_cubit.listingId}',
                        title: state.listing?.title ?? '',
                        collapsed: collapsed,
                        isFavorite: null,
                        onBack: _close,
                        onFavorite: _save,
                      ),
                    ),
                    ...switch (state.status) {
                      ProductDetailStatus.loading => [
                        const SliverPadding(
                          padding: EdgeInsets.all(12),
                          sliver: SliverToBoxAdapter(
                            child: ProductDetailSkeleton(),
                          ),
                        ),
                      ],
                      ProductDetailStatus.failure => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: FeedbackView(
                            icon: AppIcons.offline,
                            title: _l10n.productLoadErrorTitle,
                            message: _l10n.productLoadErrorBody,
                            action: FilledButton(
                              onPressed: _cubit.load,
                              child: Text(_l10n.retry),
                            ),
                          ),
                        ),
                      ],
                      ProductDetailStatus.ready => [
                        _content(
                          detail!,
                          previousPrice: state.lastChange?.previousPrice,
                          bottomInset: MediaQuery.paddingOf(bodyContext).bottom,
                        ),
                      ],
                    },
                  ],
                ),
              ),
            ),
            bottomNavigationBar: detail == null
                ? null
                : ProductDetailBottomBar(
                    detail: detail,
                    isSubmitting: state.isSubmitting,
                    onChat: () => _onChat(detail),
                    onSave: _save,
                    onCall:
                        phone != null &&
                            RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)
                        ? () => _call(phone)
                        : null,
                    onEdit: () => _onEdit(detail),
                    onBoost: () => _onPromote(detail),
                    onFeature: () => _onPromote(detail),
                  ),
          ),
        );
      },
    );
  }

  Widget _content(
    ProductDetail detail, {
    int? previousPrice,
    required double bottomInset,
  }) {
    final category = detail.category;
    final categoryId = detail.listing.categoryId ?? category?.id;
    final sections = <Widget>[
      ProductDetailSummary(detail: detail, previousPrice: previousPrice),
      if (!detail.isOwner && detail.isAvailable && detail.canMakeOffer)
        ProductDealSection(
          key: ValueKey(detail.listing.id),
          detail: detail,
          signedIn: _signedIn,
        ),
      if (!detail.isOwner)
        ProductDetailSellerCard(
          key: ValueKey(detail.seller.id),
          detail: detail,
          signedIn: _signedIn,
        ),
      ProductDetailDescription(description: detail.listing.description),
      if (category != null && category.attributes.isNotEmpty)
        ProductDetailAttributes(
          category: category,
          values: detail.listing.attributes,
        ),
      ProductDetailSafetyTips(
        onReport: () => reportListing(context, detail.listing.id),
      ),
    ];

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          // Chừa chỗ cho thanh hành động phía dưới (body vẽ tràn dưới thanh)
          padding: const EdgeInsets.all(12),
          sliver: SliverList.separated(
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) =>
                FadeSlideIn(index: index, child: sections[index]),
          ),
        ),
        if (categoryId != null && categoryId.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: ProductSimilarListings(
              scrollController: _scrollController,
              key: ValueKey((detail.listing.id, categoryId)),
              listingId: detail.listing.id,
              categoryId: categoryId,
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 16 + bottomInset)),
      ],
    );
  }
}
