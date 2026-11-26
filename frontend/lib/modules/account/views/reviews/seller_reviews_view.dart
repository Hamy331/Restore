import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../bloc/public_profile/public_profile_cubit.dart';
import '../../bloc/public_profile/public_profile_state.dart';
import '../../models/profile_models.dart';
import '../../repositories/profile_repository.dart';
import '../public_profile/profile_about.dart';
import '../public_profile/profile_reviews.dart';
import '../public_profile/seller_profile_summary.dart';
import 'widgets/contact_details_panel.dart';
import 'widgets/profile_flip_card.dart';

/// Trang đánh giá của một người bán (`/users/:id/reviews`, và "Đánh giá của
/// tôi" ở tài khoản): thẻ hồ sơ xoay được, rồi các tab Đánh giá / Giới thiệu /
/// Liên hệ (Liên hệ chỉ có ở cửa hàng). Lật thẻ sang mặt sau = mở tab Liên
/// hệ và ngược lại. Điện thoại và desktop dùng chung bố cục, desktop giới hạn
/// bề ngang ở giữa trang.
class SellerReviewsView extends StatelessWidget {
  const SellerReviewsView({
    super.key,
    required this.userId,
    this.tab = SellerReviewsTab.reviews,
    this.repository,
  });

  final String userId;

  /// Tab mở sẵn. Liên hệ chỉ có ở cửa hàng; người thường mở Liên hệ thì
  /// rơi về Đánh giá
  final SellerReviewsTab tab;
  final ProfileRepository? repository;

  static const path = 'reviews';

  /// Đường dẫn trang đánh giá của [userId], mở sẵn tab [tab]
  static String location(
    String userId, {
    SellerReviewsTab tab = SellerReviewsTab.reviews,
  }) =>
      '/users/$userId/reviews'
      '${tab == SellerReviewsTab.reviews ? '' : '?tab=${tab.name}'}';

  /// Đọc tab từ `?tab=` của đường dẫn
  static SellerReviewsTab tabOf(String? name) => SellerReviewsTab.values
      .firstWhere((t) => t.name == name, orElse: () => SellerReviewsTab.reviews);

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(userId),
    create: (_) =>
        PublicProfileCubit(repository ?? ApiProfileRepository(), userId)
          ..load(),
    child: _SellerReviewsPage(tab: tab),
  );
}

/// Các tab của trang đánh giá, theo thứ tự hiển thị
enum SellerReviewsTab { reviews, about, contact }

class _SellerReviewsPage extends StatelessWidget {
  const _SellerReviewsPage({required this.tab});
  final SellerReviewsTab tab;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<PublicProfileCubit, PublicProfileState>(
      buildWhen: (a, b) => a.profile != b.profile || a.failed != b.failed,
      builder: (context, state) {
        final p = state.profile;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/account'),
            ),
            centerTitle: true,
            title: Text(l.reviews),
          ),
          body: p == null
              ? Center(
                  child: state.failed
                      ? TextButton(
                          onPressed: context.read<PublicProfileCubit>().load,
                          child: Text(l.retry),
                        )
                      : const CircularProgressIndicator(),
                )
              : _ReviewsBody(
                  // Shop hay người thường quyết định số tab: dựng lại khi đổi
                  key: ValueKey(p.storefront.isShop),
                  profile: p,
                  initial: tab == SellerReviewsTab.contact &&
                          !p.storefront.isShop
                      ? SellerReviewsTab.reviews
                      : tab,
                ),
        );
      },
    );
  }
}

class _ReviewsBody extends StatefulWidget {
  const _ReviewsBody({
    super.key,
    required this.profile,
    required this.initial,
  });
  final ProfileData profile;
  final SellerReviewsTab initial;

  @override
  State<_ReviewsBody> createState() => _ReviewsBodyState();
}

class _ReviewsBodyState extends State<_ReviewsBody>
    with SingleTickerProviderStateMixin {
  late final bool _shop = widget.profile.storefront.isShop;
  late final _tabs = TabController(
    length: _shop ? 3 : 2,
    initialIndex: widget.initial.index,
    vsync: this,
  )..addListener(_syncCard);

  /// Mặt sau của thẻ đang hiện (đồng bộ với tab Liên hệ)
  late bool _back = widget.initial == SellerReviewsTab.contact;

  void _syncCard() {
    final back = _shop && _tabs.index == 2;
    if (back != _back) setState(() => _back = back);
  }

  void _flip(bool back) {
    setState(() => _back = back);
    _tabs.animateTo(back ? 2 : 0);
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_syncCard)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!, p = widget.profile;
    final s = p.storefront;
    final tabBar = TabBar(
      controller: _tabs,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorColor: storefrontOrange,
      labelColor: storefrontOrange,
      unselectedLabelColor: Colors.black87,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      tabs: [
        Tab(text: l.reviews),
        Tab(text: l.profAbout),
        if (_shop) Tab(text: l.revTabContact),
      ],
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ProfileFlipCard(
                      key: const ValueKey('reviews-flip-card'),
                      profile: p,
                      showBack: _back,
                      onFlip: _shop ? _flip : null,
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(pinned: true, delegate: _TabsHeader(tabBar)),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              ProfileReviews(profile: p),
              ProfileAbout(
                profile: p,
                followerCount: s.verified ? s.shopFollowers : p.followerCount,
                onFollowers: s.verified
                    ? null
                    : () =>
                          context.push('/users/${p.id}/follows?tab=followers'),
                onFollowing: () =>
                    context.push('/users/${p.id}/follows?tab=following'),
              ),
              if (_shop) ContactDetailsPanel(profile: p),
            ],
          ),
        ),
      ),
    );
  }
}

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
