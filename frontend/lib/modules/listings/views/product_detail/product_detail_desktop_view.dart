import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:restore/modules/content/views/community_content_view.dart'
    show reportListing;
import 'package:restore/modules/shell/widgets/desktop_chat_controller.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../boost/views/boost_listing/boost_listing_view.dart';
import '../../bloc/product_detail/product_detail_cubit.dart';
import '../../bloc/product_detail/product_detail_state.dart';
import '../../models/product_detail.dart';
import '../edit_listing/edit_listing_view.dart';
import 'widgets/product_chat_sheet.dart';
import 'widgets/product_detail_attributes.dart';
import 'widgets/product_detail_bottom_bar.dart';
import 'widgets/product_detail_description.dart';
import 'widgets/product_detail_offer_sheet.dart';
import 'widgets/product_detail_safety_tips.dart';
import 'widgets/product_detail_seller_card.dart';
import 'widgets/product_detail_skeleton.dart';
import 'widgets/product_detail_summary.dart';
import 'widgets/product_similar_listings.dart';

/// Chi tiết sản phẩm trên web desktop: ảnh + thumbnail bên trái, giá và
/// nút mua bên phải; dưới là mô tả, thông số và thẻ người bán, cuối trang
/// là tin tương tự. Dùng lại các widget của bản điện thoại.
class ProductDetailDesktopView extends StatefulWidget {
  const ProductDetailDesktopView({super.key});

  @override
  State<ProductDetailDesktopView> createState() =>
      _ProductDetailDesktopViewState();
}

class _ProductDetailDesktopViewState extends State<ProductDetailDesktopView> {
  final _scrollController = ScrollController();
  late final AppLifecycleListener _lifecycle;

  ProductDetailCubit get _cubit => context.read<ProductDetailCubit>();
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _cubit.pauseLiveUpdates(),
      onShow: () => _cubit.resumeLiveUpdates(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _signedIn() {
    if (context.isSignedIn) return true;
    context.go(loginPath(from: '/listings/${_cubit.listingId}'));
    return false;
  }

  void _save() {
    if (_signedIn()) _cubit.toggleFavorite();
  }

  /// Nhắn người bán: gửi câu hỏi rồi mở cuộc trò chuyện trong cửa sổ nổi
  Future<void> _onChat(ProductDetail detail) async {
    if (!_signedIn()) return;
    final id = await showProductChatSheet(context, detail);
    if (!mounted || id == null) return;
    if (!openDesktopChat(context, conversationId: id)) {
      context.push('/messages/$id');
    }
  }

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

  Future<void> _onEdit(ProductDetail detail) async {
    await context.push<bool>(EditListingView.location(detail.listing.id));
    if (mounted) await _cubit.refresh();
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
        final slivers = switch (state.status) {
          ProductDetailStatus.loading => [
            SliverToBoxAdapter(child: _Breadcrumb(title: state.listing?.title)),
            const SliverToBoxAdapter(
              child: DesktopBox(child: ProductDetailSkeleton()),
            ),
          ],
          ProductDetailStatus.failure => [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 460,
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
            ),
          ],
          ProductDetailStatus.ready => _content(
            detail!,
            previousPrice: state.lastChange?.previousPrice,
            submitting: state.isSubmitting,
          ),
        };
        return DesktopPage(controller: _scrollController, slivers: slivers);
      },
    );
  }

  List<Widget> _content(
    ProductDetail detail, {
    int? previousPrice,
    required bool submitting,
  }) {
    final category = detail.category;
    final categoryId = detail.listing.categoryId ?? category?.id;
    final phone = detail.seller.phone?.replaceAll(RegExp(r'[\s().-]'), '');

    final details = <Widget>[
      if (!detail.isOwner && detail.isAvailable && detail.canMakeOffer)
        ProductDealSection(
          key: ValueKey(detail.listing.id),
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

    return [
      SliverToBoxAdapter(
        child: _Breadcrumb(
          title: detail.listing.title,
          categoryName: category?.name.of(context),
          onCategory: category == null
              ? null
              : () => context.push(
                  CategoryDetailView.location(category.id),
                  extra: category,
                ),
        ),
      ),
      SliverToBoxAdapter(
        child: DesktopBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 460,
                child: _Gallery(
                  images: detail.listing.images,
                  isFavorite: detail.isFavorite,
                  onFavorite: _save,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductDetailSummary(
                      detail: detail,
                      previousPrice: previousPrice,
                    ),
                    const SizedBox(height: 16),
                    // Thanh hành động (Nhắn tin / Trả giá / Mua ngay, hoặc
                    // Sửa tin / Đẩy tin với chủ tin) đặt ngay dưới giá
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: MediaQuery.removePadding(
                            context: context,
                            removeBottom: true,
                            child: ProductDetailBottomBar(
                              detail: detail,
                              isSubmitting: submitting,
                              onChat: () => _onChat(detail),
                              onSave: _save,
                              onCall:
                                  phone != null &&
                                      RegExp(
                                        r'^\+?[0-9]{7,15}$',
                                      ).hasMatch(phone)
                                  ? () => _call(phone)
                                  : null,
                              onEdit: () => _onEdit(detail),
                              onBoost: () => _onPromote(detail),
                              onFeature: () => _onPromote(detail),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < details.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      details[i],
                    ],
                  ],
                ),
              ),
              if (!detail.isOwner) ...[
                const SizedBox(width: 20),
                SizedBox(
                  width: 380,
                  child: ProductDetailSellerCard(
                    key: ValueKey(detail.seller.id),
                    detail: detail,
                    signedIn: _signedIn,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      if (categoryId != null && categoryId.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.only(top: 24),
          sliver: ProductSimilarListings(
            scrollController: _scrollController,
            key: ValueKey((detail.listing.id, categoryId)),
            listingId: detail.listing.id,
            categoryId: categoryId,
          ),
        ),
    ];
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.title, this.categoryName, this.onCategory});
  final String? title;
  final String? categoryName;
  final VoidCallback? onCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const sep = Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        AppIcons.chevronRight,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
    const link = TextStyle(fontSize: 13, color: AppColors.primaryDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/home'),
            child: Text(l10n.homeTitle, style: link),
          ),
          if (categoryName != null) ...[
            sep,
            InkWell(
              onTap: onCategory,
              child: Text(categoryName!, style: link),
            ),
          ],
          if (title != null && title!.isNotEmpty) ...[
            sep,
            Flexible(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ảnh lớn + hàng thumbnail; rê chuột vào thumbnail để đổi ảnh như Shopee
class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.images,
    required this.isFavorite,
    required this.onFavorite,
  });

  final List<String> images;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;
  int _firstThumb = 0;
  static const _visibleThumbs = 5;

  void _select(int index) => setState(() {
    _index = index;
    if (index < _firstThumb) _firstThumb = index;
    if (index >= _firstThumb + _visibleThumbs) {
      _firstThumb = index - _visibleThumbs + 1;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final images = widget.images;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final index = images.isEmpty ? 0 : _index.clamp(0, images.length - 1);
    final end = (_firstThumb + _visibleThumbs).clamp(0, images.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: AppColors.cream,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.isEmpty)
                    const Icon(
                      AppIcons.image,
                      size: 48,
                      color: AppColors.textSecondary,
                    )
                  else
                    AppLocalImage(path: images[index], fit: BoxFit.contain),
                  if (images.length > 1) ...[
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_left,
                          onTap: () =>
                              _select((index - 1 + images.length) % images.length),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_right,
                          onTap: () => _select((index + 1) % images.length),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = _firstThumb; i < end; i++) ...[
                if (i > _firstThumb) const SizedBox(width: 8),
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _index = i),
                    child: GestureDetector(
                      onTap: () => _select(i),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: i == index
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppLocalImage(
                              path: images[i],
                              cacheWidth: 200,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              for (var i = end - _firstThumb; i < _visibleThumbs; i++) ...[
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              vi ? 'Chia sẻ:' : 'Share:',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: vi ? 'Sao chép liên kết' : 'Copy link',
              onPressed: () => TSnackBarHelper.showInfo(
                context,
                message: Uri.base.toString(),
              ),
              icon: const Icon(AppIcons.link, size: 16),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onFavorite,
              icon: Icon(
                widget.isFavorite ? AppIcons.savedListing : AppIcons.favorite,
                size: 18,
                color: widget.isFavorite
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
              label: Text(
                widget.isFavorite ? l10n.homeUnsaveListing : l10n.homeSaveListing,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .88),
    shape: const CircleBorder(),
    elevation: 1,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 20)),
    ),
  );
}
