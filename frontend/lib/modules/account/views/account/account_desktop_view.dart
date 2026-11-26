import 'package:restore/core/routes/profile_path.dart';
import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/desktop/desktop_page_title.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/views/my_reviews/my_reviews_view.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';
import 'package:restore/modules/credits/views/credit_wallet/credit_wallet_view.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/plans/views/plans/plans_view.dart';
import 'package:restore/shared/widgets/app_image_icon.dart';

import '../../../feeds/bloc/feeds/feeds_cubit.dart';
import '../../../feeds/repositories/feeds_repository.dart';
import '../../bloc/account_listings/account_listings_cubit.dart';
import '../../bloc/account_listings/account_listings_state.dart';
import '../../bloc/user_profile/user_profile_cubit.dart';
import '../../bloc/user_profile/user_profile_state.dart';
import '../../models/account_listing.dart';
import '../../models/profile_models.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/profile_posts.dart';
import '../edit_profile/edit_profile_view.dart';
import 'widgets/account_listings.dart';
import 'widgets/my_account_header.dart';

enum _Section { listings, posts }

/// Trang "Hồ sơ của tôi" trên web desktop, nằm bên phải menu Tài khoản
/// (AccountDesktopShell): thông tin hồ sơ, ví / gói, tin đăng và bài viết.
class AccountDesktopView extends StatefulWidget {
  const AccountDesktopView({super.key});

  @override
  State<AccountDesktopView> createState() => _AccountDesktopViewState();
}

class _AccountDesktopViewState extends State<AccountDesktopView> {
  _Section _section = _Section.listings;
  FeedsCubit? _posts;

  @override
  void dispose() {
    _posts?.close();
    super.dispose();
  }

  void _showSection(_Section value) {
    final profile = context.read<UserProfileCubit>().state.profile;
    if (value == _Section.posts && _posts == null && profile != null) {
      _posts =
          FeedsCubit(
              repository: context.read<FeedsRepository>(),
              authorId: profile.id,
            )
            ..load()
            ..loadMe();
    }
    setState(() => _section = value);
  }

  Future<void> _openFollows(String userId, FollowListKind kind) async {
    await context.push('/users/$userId/follows?tab=${kind.name}&me=1');
    if (mounted) context.read<UserProfileCubit>().load();
  }

  /// Trang sửa hồ sơ dùng chung cubit nên lưu xong hồ sơ cập nhật ngay
  Future<void> _openEditProfile() async {
    final cubit = context.read<UserProfileCubit>();
    if (cubit.state.profile == null) return;
    final saved = await context.push<bool>(EditProfileView.path, extra: cubit);
    if (!mounted || saved != true) return;
    final profile = cubit.state.profile!;
    context.read<AuthBloc>().add(
      ProfileIdentityUpdated(
        id: profile.id,
        fullName: profile.fullName,
        username: profile.username,
        avatarUrl: profile.avatarUrl,
        email: profile.email,
        phone: profile.phone,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileSaved),
          duration: const Duration(seconds: 2),
        ),
      );
    _posts?.load();
    _posts?.loadMe(refresh: true);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.metrics.extentAfter > 400) {
      return false;
    }
    if (_section == _Section.listings) {
      context.read<AccountListingsCubit>().loadMore();
    } else {
      _posts?.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final userCubit = context.read<UserProfileCubit>();

    return Material(
      color: AppColors.surface,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          slivers: [
            // Tiêu đề trang: cùng widget với các mục khác trong menu
            SliverToBoxAdapter(
              // "Xem trang" nằm trên avatar (như điện thoại), nên tiêu đề chỉ
              // còn nút sửa hồ sơ
              child: DesktopPageTitle(
                title: l.myAccount,
                subtitle: t(
                  'Quản lý hồ sơ, tin đăng và bài viết của bạn',
                  'Manage your profile, listings and posts',
                ),
                trailing: FilledButton.icon(
                  onPressed: _openEditProfile,
                  icon: const Icon(AppIcons.edit, size: 17),
                  label: Text(l.accEditPage),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionPrimary,
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<UserProfileCubit, UserProfileState>(
                  builder: (context, userState) {
                    final profile = userState.profile;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (userState.failed)
                          Center(
                            child: TextButton(
                              onPressed: userCubit.load,
                              child: Text(l.accLoadError),
                            ),
                          )
                        else
                          MyAccountHeader(
                            profile: profile,
                            onViewProfile: profile == null
                                ? null
                                : () => context.push(profilePath(id: profile.id, username: profile.username)),
                            onRatingTap: () =>
                                context.push(MyReviewsView.ratingsPath),
                            onBioTap: _openEditProfile,
                            onFollowingTap: profile == null
                                ? null
                                : () => _openFollows(
                                    profile.id,
                                    FollowListKind.following,
                                  ),
                            onFollowersTap: profile == null
                                ? null
                                : () => _openFollows(
                                    profile.id,
                                    FollowListKind.followers,
                                  ),
                            extraStat:
                                BlocBuilder<
                                  AccountListingsCubit,
                                  AccountListingsState
                                >(
                                  builder: (context, state) => ProfileStat(
                                    value:
                                        '${state.count(AccountListingStatus.visible)}',
                                    label: l.accListings,
                                    onTap: () =>
                                        _showSection(_Section.listings),
                                  ),
                                ),
                          ),
                        const SizedBox(height: 24),
                        // Ví xu, gói tài khoản, đăng tin: ba ô cao bằng nhau dù
                        // chữ mô tả xuống một hay hai dòng
                        // Khung hẹp (tablet): ba ô xếp dọc cho khỏi bóp chữ
                        LayoutBuilder(
                          builder: (context, box) {
                            final cards = <Widget>[
                              _QuickCard(
                                image: AppImages.uiIcons.coin,
                                fallback: AppIcons.wallet,
                                title: l.accCoins,
                                subtitle: t(
                                  'Nạp xu, đẩy tin, Hot sale',
                                  'Top up, boost, Hot sale',
                                ),
                                onTap: () =>
                                    context.push(CreditWalletView.path),
                              ),
                              _QuickCard(
                                image: AppImages.uiIcons.crown,
                                fallback: AppIcons.pro,
                                title: l.accProPlan,
                                subtitle: t(
                                  'Nâng cấp để đăng nhiều tin hơn',
                                  'Upgrade for more listings',
                                ),
                                onTap: () => context.push(PlansView.path),
                              ),
                              _QuickCard(
                                image: AppImages.uiIcons.post,
                                fallback: AppIcons.post,
                                title: t('Đăng tin mới', 'New listing'),
                                subtitle: t(
                                  'Bán hoặc trao đổi món đồ của bạn',
                                  'Sell or swap an item',
                                ),
                                onTap: () => context.push(
                                  CreateListingStep.category.path,
                                ),
                              ),
                            ];
                            if (box.maxWidth < 620) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final card in cards) ...[
                                    card,
                                    if (card != cards.last)
                                      const SizedBox(height: 10),
                                  ],
                                ],
                              );
                            }
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final card in cards) ...[
                                    Expanded(child: card),
                                    if (card != cards.last)
                                      const SizedBox(width: 14),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            _SectionTab(
                              label: l.accListings,
                              selected: _section == _Section.listings,
                              onTap: () => _showSection(_Section.listings),
                            ),
                            _SectionTab(
                              label: l.accPosts,
                              selected: _section == _Section.posts,
                              onTap: profile == null
                                  ? null
                                  : () => _showSection(_Section.posts),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_section == _Section.listings)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                sliver: BlocBuilder<AccountListingsCubit, AccountListingsState>(
                  builder: (context, state) => SliverMainAxisGroup(
                    slivers: accountListingSlivers(state),
                  ),
                ),
              )
            else if (_posts != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: ProfilePostsSliver(cubit: _posts!),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.image,
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String image;
  final IconData fallback;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cream,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppImageIcon(image, size: 44, fallback: fallback),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 3 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}
