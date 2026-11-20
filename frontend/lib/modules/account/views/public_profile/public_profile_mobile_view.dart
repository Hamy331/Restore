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
import '../../bloc/public_profile/public_profile_cubit.dart';
import '../../bloc/public_profile/public_profile_state.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_posts.dart';
import 'seller_activity_preview.dart';
import 'seller_listings.dart';
import 'seller_profile_summary.dart';

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
    length: 3,
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
              bottom: p == null
                  ? null
                  : TabBar(
                      controller: _tabs,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: storefrontOrange,
                      labelColor: storefrontOrange,
                      unselectedLabelColor: Colors.black87,
                      tabs: [
                        Tab(
                          text: s!.isShop
                              ? l.planShop
                              : s.isPro
                              ? l.planPro
                              : l.sellerPersonal,
                        ),
                        Tab(text: l.accActivity),
                        Tab(text: l.reviews),
                      ],
                    ),
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
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          SellerListings(
                            userId: p.id,
                            refresh: () async {
                              await Future.wait([cubit.load(), posts.load()]);
                            },
                            summary: Column(
                              children: [
                                SellerProfileSummary(
                                  profile: p,
                                  showShopLogo: widget.returnShopFollow,
                                  following: p.followsSeller,
                                  followerCount: s!.verified
                                      ? s.shopFollowers
                                      : p.followerCount,
                                  onFollow: own ? null : () => _follow(p),
                                  onCall:
                                      !own && phone != null && phone.isNotEmpty
                                      ? () => _call(phone)
                                      : null,
                                  onReviews: () => _tabs.animateTo(2),
                                  onFollowers: s.verified
                                      ? null
                                      : () => context.push(
                                          '/users/${p.id}/follows?tab=followers',
                                        ),
                                  onFollowing: () => context.push(
                                    '/users/${p.id}/follows?tab=following',
                                  ),
                                  onCatalog: s.verified
                                      ? () => _catalog(p)
                                      : null,
                                ),
                                SellerActivityPreview(
                                  open: () => _tabs.animateTo(1),
                                ),
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
                              onNotification: (n) =>
                                  feedScrollListener(posts, n),
                              child: CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [ProfilePostsSliver(cubit: posts)],
                              ),
                            ),
                          ),
                          ProfileReviews(profile: p),
                        ],
                      ),
                    ),
                  ),
            bottomNavigationBar: !contact
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
