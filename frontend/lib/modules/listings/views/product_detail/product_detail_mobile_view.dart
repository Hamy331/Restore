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
import 'widgets/product_detail_attributes.dart';
import 'widgets/product_detail_bottom_bar.dart';
import 'widgets/product_detail_description.dart';
import 'widgets/product_detail_header.dart';
import 'widgets/product_detail_offer_sheet.dart';
import 'widgets/product_detail_purchase_sheet.dart';
import 'widgets/product_detail_safety_tips.dart';
import 'widgets/product_detail_seller_card.dart';
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

  void _comingSoon() =>
      TSnackBarHelper.showInfo(context, message: _l10n.featureComingSoon);

  void _openChat(String conversationId) =>
      context.push('/messages/$conversationId');

  Future<void> _onChat() async {
    final id = await _cubit.openConversation();
    if (!mounted) return;
    id == null
        ? TSnackBarHelper.showError(context, message: _l10n.productActionFailed)
        : _openChat(id);
  }

  Future<void> _onOffer(ProductDetail detail) async {
    final amount = await showProductOfferSheet(
      context,
      price: detail.listing.price!,
    );
    if (amount == null || !mounted) return;
    _afterSubmit(await _cubit.sendOffer(amount), _l10n.productOfferSent);
  }

  Future<void> _onBuy(ProductDetail detail) async {
    final note = await showProductPurchaseSheet(context, detail: detail);
    if (note == null || !mounted) return;
    _afterSubmit(
      await _cubit.requestPurchase(note: note.isEmpty ? null : note),
      _l10n.productBuySent,
    );
  }

  void _afterSubmit(ProductActionResult result, String successMessage) {
    if (!mounted) return;
    switch (result) {
      case ProductActionSent(:final conversationId):
        TSnackBarHelper.showSuccess(context, message: successMessage);
        _openChat(conversationId);
      // Đã báo thay đổi qua _onChanged, người mua xem lại rồi thao tác tiếp
      case ProductActionOutdated():
        break;
      case ProductActionFailed():
        TSnackBarHelper.showError(context, message: _l10n.productActionFailed);
    }
  }

  /// Báo thay đổi vừa phát hiện. Giá đổi hoặc hết hàng thì đóng sheet trả
  /// giá / mua ngay đang mở để người mua không gửi theo thông tin cũ.
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

    if (change.kind == ProductDetailChangeKind.unavailable ||
        change.kind == ProductDetailChangeKind.price) {
      final page = ModalRoute.of(context);
      Navigator.of(context).popUntil((route) => route == page);
    }

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
                        isFavorite: detail == null || detail.isOwner
                            ? null
                            : detail.isFavorite,
                        onBack: _close,
                        onFavorite: _cubit.toggleFavorite,
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
                    onChat: _onChat,
                    onOffer: () => _onOffer(detail),
                    onBuy: () => _onBuy(detail),
                    onEdit: _comingSoon,
                    onBoost: () => context.push('/boost/${detail.listing.id}'),
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
    final sections = <Widget>[
      ProductDetailSummary(detail: detail, previousPrice: previousPrice),
      if (!detail.isOwner)
        ProductDetailSellerCard(
          seller: detail.seller,
          activeListings: detail.sellerActiveListings,
          // TODO: mở trang người bán khi có route hồ sơ công khai
          onTap: _comingSoon,
        ),
      ProductDetailDescription(description: detail.listing.description),
      if (category != null && category.attributes.isNotEmpty)
        ProductDetailAttributes(
          category: category,
          values: detail.listing.attributes,
        ),
      ProductDetailSafetyTips(onReport: _comingSoon),
    ];

    return SliverPadding(
      // Chừa chỗ cho thanh hành động phía dưới (body vẽ tràn dưới thanh)
      padding: EdgeInsets.fromLTRB(12, 12, 12, 16 + bottomInset),
      sliver: SliverList.separated(
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) =>
            FadeSlideIn(index: index, child: sections[index]),
      ),
    );
  }
}
