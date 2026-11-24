import 'profile_reviews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'profile_about.dart';
import 'seller_activity_preview.dart';
import 'seller_listings.dart';
import 'seller_profile_summary.dart';
import 'shop_poster_strip.dart';

class PublicProfileMobileView extends StatefulWidget {
  const PublicProfileMobileView({
    super.key,
    this.returnShopFollow = false,
    this.openReviews = false,
  });
  final bool openReviews;
  final bool returnShopFollow;
  @override
  State<PublicProfileMobileView> createState() =>
      _PublicProfileMobileViewState();
}

class _PublicProfileMobileViewState extends State<PublicProfileMobileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 4,
    initialIndex: widget.openReviews ? 2 : 0,
    vsync: this,
  );
  bool _chatBusy = false;
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

  Future<void> _catalog(ProfileData p) async {
    final result = await context.push<bool>(
      '/shops/${p.storefront.shopId}?catalog=1',
    );
    if (!mounted || result == null) return;
    setState(() => _shopFollowing = result);
    await context.read<PublicProfileCubit>().load();
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
        // Desktop: thẻ hồ sơ cột trái (có sẵn Nhắn tin + Gọi), tab + lưới tin
        // cột phải, không có thanh nút dưới đáy
        final wide = isDesktopLayout(context);
        Widget summary() => SellerProfileSummary(
          profile: p!,
          showShopLogo: widget.returnShopFollow,
          following: p.followsSeller,
          onFollow: own ? null : () => _follow(p),
          onCall: !own && phone != null && phone.isNotEmpty
              ? () => _call(phone)
              : null,
          onChat: wide && contact && !_chatBusy ? () => _chat(p) : null,
          onReviews: () => _tabs.animateTo(2),
          onCatalog: s!.verified ? () => _catalog(p) : null,
        );
        // Poster đang chạy của cửa hàng Đối tác, dưới phần đầu trang
        Widget posters() => s!.isShop
            ? ShopPosterStrip(key: ValueKey(s.shopId), shopId: s.shopId!)
            : const SizedBox.shrink();
        TabBar tabBar() => TabBar(
          controller: _tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          // 4 tab vừa màn hình hẹp (390px) không cắt chữ
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          indicatorColor: storefrontOrange,
          labelColor: storefrontOrange,
          unselectedLabelColor: Colors.black87,
          tabs: [
            Tab(text: l.accListings),
            Tab(text: (s?.isShop ?? false) ? l.feedsTitle : l.accActivity),
            Tab(text: l.reviews),
            Tab(text: l.profAbout),
          ],
        );
        Widget tabs() => TabBarView(
          controller: _tabs,
          children: [
            SellerListings(
              userId: p!.id,
              grid: wide,
              refresh: () async {
                await Future.wait([cubit.load(), posts.load()]);
              },
              summary: wide
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        SellerActivityPreview(open: () => _tabs.animateTo(1)),
                        const Divider(
                          thickness: 5,
                          height: 5,
                          color: Color(0xfff5f5f5),
                        ),
                      ],
                    ),
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
            ProfileReviews(profile: p),
            ProfileAbout(
              profile: p,
              followerCount: s!.verified ? s.shopFollowers : p.followerCount,
              onFollowers: s.verified
                  ? null
                  : () => context.push('/users/${p.id}/follows?tab=followers'),
              onFollowing: () =>
                  context.push('/users/${p.id}/follows?tab=following'),
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
            appBar: AppBar(
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
              bottom: p == null || !wide ? null : tabBar(),
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
                : wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 320,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              summary(),
                              posters(),
                              SellerActivityPreview(
                                open: () => _tabs.animateTo(1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Color(0xffeeeeee)),
                      Expanded(child: tabs()),
                    ],
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      // Bố cục như Carousell: ảnh bìa, avatar giữa, tên + nhãn,
                      // đánh giá + thời gian ở ReStore, rồi tab ghim khi cuộn
                      child: NestedScrollView(
                        headerSliverBuilder: (_, _) => [
                          SliverToBoxAdapter(
                            child: Column(children: [summary(), posters()]),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _TabsHeader(tabBar()),
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
  _TabsHeader(this.bar);
  final TabBar bar;

  @override
  double get minExtent => bar.preferredSize.height + 1;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            bar,
            const Divider(height: 1, color: Color(0xffeeeeee)),
          ],
        ),
      );

  @override
  bool shouldRebuild(_TabsHeader old) => old.bar != bar;
}
