import 'package:restore/modules/content/views/report_user_sheet.dart';
import 'package:restore/core/routes/profile_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/modules/trusted_shop/repositories/trusted_shop_repository.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_verification_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';
import 'package:restore/modules/feeds/bloc/feeds/feeds_cubit.dart';
import 'package:restore/modules/feeds/widgets/feed_post_list.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import '../../bloc/public_profile/public_profile_cubit.dart';
import '../../bloc/public_profile/public_profile_state.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_posts.dart';
import '../reviews/seller_reviews_view.dart';
import 'seller_listings.dart';
import 'seller_profile_summary.dart';
import 'shop_poster_strip.dart';

class PublicProfileMobileView extends StatefulWidget {
  const PublicProfileMobileView({
    super.key,
    this.returnShopFollow = false,
  });
  final bool returnShopFollow;
  @override
  State<PublicProfileMobileView> createState() =>
      _PublicProfileMobileViewState();
}

class _PublicProfileMobileViewState extends State<PublicProfileMobileView>
    with SingleTickerProviderStateMixin {
  // Chỉ Tin đăng và Bài viết; đánh giá, giới thiệu, liên hệ ở trang riêng
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _chatBusy = false, _certBusy = false;
  bool? _shopFollowing;
  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _chat(ProfileData profile) async {
    if (_chatBusy) return;
    setState(() => _chatBusy = true);
    try {
      final id = await ApiChatRepository().startConversation(profile.id);
      if (mounted) await context.push('/messages/$id');
    } catch (_) {
      if (mounted) _notice(AppLocalizations.of(context)!.productActionFailed);
    } finally {
      if (mounted) setState(() => _chatBusy = false);
    }
  }

  Future<void> _call(String phone) async {
    final l = AppLocalizations.of(context)!;
    try {
      if (await launchUrl(
        Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')),
      )) {
        return;
      }
    } catch (_) {
      /* No telephone handler on this device. */
    }
    if (mounted) _notice('${l.listingCallUnavailable} $phone');
  }

  Future<void> _follow(ProfileData p) async {
    final cubit = context.read<PublicProfileCubit>();
    await cubit.toggleFollow();
    final current = cubit.state.profile;
    if (mounted &&
        p.storefront.verified &&
        current != null &&
        p.followsSeller != current.followsSeller) {
      setState(() => _shopFollowing = current.followsSeller);
    }
  }

  /// Sao chép liên kết trang shop / trang cá nhân (web: kèm tên miền đang chạy)
  Future<void> _share(ProfileData p) async {
    final l = AppLocalizations.of(context)!;
    final shopId = p.storefront.shopId;
    final path = shopId == null
        ? profilePath(id: p.id, username: p.username)
        : ShopDetailView.location(shopId, name: storefrontName(p));
    final base = Uri.base;
    final url = base.scheme == 'http' || base.scheme == 'https'
        ? '${base.origin}$path'
        : path;
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      _notice(shopId == null ? l.profProfileLinkCopied : l.profLinkCopied);
    }
  }

  /// Bảng chứng nhận của shop (mã, ngày xác minh); tải thông tin shop khi bấm
  Future<void> _certificate(ProfileData p) async {
    final shopId = p.storefront.shopId;
    if (shopId == null || _certBusy) return;
    _certBusy = true;
    ShopModel? shop;
    try {
      shop = (await ApiTrustedShopRepository().getShop(shopId)).shop;
    } catch (_) {
      // Không tải được thì vẫn mở bảng giải thích chung
    } finally {
      _certBusy = false;
    }
    if (mounted) await showShopVerificationSheet(context, shop: shop);
  }

  void _close() {
    if (context.canPop()) {
      context.pop(widget.returnShopFollow ? _shopFollowing : null);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PublicProfileCubit>(),
        posts = context.read<FeedsCubit>();
    return BlocConsumer<PublicProfileCubit, PublicProfileState>(
      listenWhen: (_, s) => s.actionFailed,
      listener: (_, _) => _notice(l.feedActionError),
      builder: (context, state) {
        final p = state.profile;
        final s = p?.storefront;
        final own = p != null && context.currentUser?.id == p.id;
        final phone = s?.phone?.trim();
        final contact = p != null && !own;
        // Desktop: cùng bố cục với điện thoại (bìa + thẻ + tab), rộng hơn; Nhắn
        // tin + Gọi nằm trong thẻ, không có thanh nút dưới đáy
        final wide = isDesktopLayout(context);
        // Điện thoại: ảnh bìa (hoặc nền màu cố định) lên tận mép trên, nút
        // quay lại nổi trên bìa thay cho thanh tiêu đề
        final shopCover = p != null && !wide;
        Widget summary() => SellerProfileSummary(
          profile: p!,
          showShopLogo: widget.returnShopFollow,
          following: p.followsSeller,
          onFollow: own ? null : () => _follow(p),
          // Điện thoại đã có Nhắn tin + Gọi ở thanh dưới đáy
          onCall: wide && !own && phone != null && phone.isNotEmpty
              ? () => _call(phone)
              : null,
          onChat: wide && contact && !_chatBusy ? () => _chat(p) : null,
          // Trang đánh giá riêng (thẻ xoay, lời khen, liên hệ): bấm số sao
          // mở tab Đánh giá, bấm khung hồ sơ hoặc "trên ReStore" mở Giới thiệu
          onReviews: () => context.push(SellerReviewsView.location(p.id)),
          onBack: shopCover ? _close : null,
          onShare: () => _share(p),
          onAbout: () => context.push(
            SellerReviewsView.location(p.id, tab: SellerReviewsTab.about),
          ),
          onCertificate: s!.verified ? () => _certificate(p) : null,
          onReport: own
              ? null
              : () => reportUser(
                  context,
                  userId: p.id,
                  username: p.username,
                ),
        );
        // Poster đang chạy của cửa hàng Đối tác, dưới phần đầu trang
        // Desktop: poster rộng tối đa 560px để không chiếm cả màn hình
        Widget posters() => s!.isShop
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 560 : double.infinity,
                  ),
                  child: ShopPosterStrip(
                    key: ValueKey(s.shopId),
                    shopId: s.shopId!,
                  ),
                ),
              )
            : const SizedBox.shrink();
        TabBar tabBar() => TabBar(
          controller: _tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: storefrontOrange,
          labelColor: storefrontOrange,
          unselectedLabelColor: Colors.black87,
          tabs: [
            Tab(text: l.accListings),
            Tab(text: (s?.isShop ?? false) ? l.feedsTitle : l.accActivity),
          ],
        );
        Widget tabs() => TabBarView(
          controller: _tabs,
          children: [
            SellerListings(
              userId: p!.id,
              // Lưới thẻ + tổng số tin + ô tìm + sắp xếp cho mọi người bán
              grid: true,
              searchable: true,
              activeCount: s!.listings,
              soldCount: s.sold,
              refresh: () async {
                await Future.wait([cubit.load(), posts.load()]);
              },
              summary: const SizedBox.shrink(),
            ),
            RefreshIndicator(
              onRefresh: posts.load,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) => feedScrollListener(posts, n),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [ProfilePostsSliver(cubit: posts)],
                ),
              ),
            ),
          ],
        );
        return PopScope(
          canPop: !widget.returnShopFollow || _shopFollowing == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: shopCover
                ? null
                : AppBar(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    centerTitle: true,
                    leading: BackButton(onPressed: _close),
                    title: Text(
                      p == null ? '' : storefrontName(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Desktop: tab nằm trên cột phải; điện thoại: tab ghim dưới đầu trang
                    // Điện thoại: tab ghim dưới đầu trang; desktop không có tab
                    bottom: null,
                  ),
            body: p == null
                ? Center(
                    child: state.failed
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.accUserNotFound),
                              TextButton(
                                onPressed: cubit.load,
                                child: Text(l.retry),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1200 : 720),
                      // Ảnh bìa, thẻ hồ sơ nổi, giới thiệu, poster, rồi tab
                      // ghim khi cuộn
                      child: NestedScrollView(
                        headerSliverBuilder: (_, _) => [
                          SliverToBoxAdapter(
                            child: Column(children: [summary(), posters()]),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _TabsHeader(
                              tabBar(),
                              // Không có thanh tiêu đề: tab ghim chừa chỗ
                              // cho thanh trạng thái
                              top: shopCover
                                  ? MediaQuery.paddingOf(context).top
                                  : 0,
                            ),
                          ),
                        ],
                        body: tabs(),
                      ),
                    ),
                  ),
            bottomNavigationBar: !contact || wide
                ? null
                : SafeArea(
                    top: false,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xffeeeeee)),
                        ),
                      ),
                      child: Center(
                        heightFactor: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: _chatBusy
                                        ? null
                                        : () => _chat(p),
                                    icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18,
                                    ),
                                    label: Text(l.productChat),
                                  ),
                                ),
                                if (phone != null && phone.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SellerCallButton(
                                      onPressed: () => _call(phone),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Thanh tab ghim dưới đầu trang hồ sơ khi cuộn
class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader(this.bar, {this.top = 0});
  final TabBar bar;

  /// Khoảng trống phía trên (thanh trạng thái) khi trang không có AppBar
  final double top;

  @override
  double get minExtent => bar.preferredSize.height + 1 + top;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(height: top),
            bar,
            const Divider(height: 1, color: Color(0xffeeeeee)),
          ],
        ),
      );

  @override
  bool shouldRebuild(_TabsHeader old) => old.bar != bar || old.top != top;
}
