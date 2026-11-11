import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feeds/bloc/feeds/feeds_cubit.dart';
import '../../../feeds/repositories/feeds_repository.dart';
import '../../bloc/account_listings/account_listings_cubit.dart';
import '../../bloc/account_listings/account_listings_state.dart';
import '../../models/account_listing.dart';
import '../../bloc/user_profile/user_profile_cubit.dart';
import '../../bloc/user_profile/user_profile_state.dart';
import '../../models/profile_models.dart';
import './widgets/account_listings.dart';
import './widgets/account_menu.dart';
import './widgets/edit_profile_dialog.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/profile_posts.dart';
import '../../../plans/views/plans/plans_view.dart';

enum _Section { listings, posts }

class AccountMobileView extends StatefulWidget {
  const AccountMobileView({super.key});

  @override
  State<AccountMobileView> createState() => _AccountMobileViewState();
}

class _AccountMobileViewState extends State<AccountMobileView> {
  _Section section = _Section.listings;

  /// Tạo khi mở mục "Bài viết" lần đầu (cần id của hồ sơ).
  FeedsCubit? posts;

  @override
  void dispose() {
    posts?.close();
    super.dispose();
  }

  void showSection(_Section value) {
    final profile = context.read<UserProfileCubit>().state.profile;
    if (value == _Section.posts && posts == null && profile != null) {
      posts =
          FeedsCubit(
              repository: context.read<FeedsRepository>(),
              authorId: profile.id,
            )
            ..load()
            ..loadMe();
    }
    setState(() => section = value);
  }

  Future<void> refresh() => Future.wait([
    context.read<UserProfileCubit>().load(),
    context.read<AccountListingsCubit>().load(),
    if (posts != null) posts!.load(),
  ]);

  Future<void> openFollows(String userId, FollowListKind kind) async {
    await context.push('/users/$userId/follows?tab=${kind.name}');
    if (mounted) context.read<UserProfileCubit>().load();
  }

  bool onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.metrics.extentAfter > 300) {
      return false;
    }
    if (section == _Section.listings) {
      context.read<AccountListingsCubit>().loadMore();
    } else {
      posts?.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final userCubit = context.read<UserProfileCubit>();
    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RefreshIndicator(
              onRefresh: refresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: onScroll,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverToBoxAdapter(
                        child: BlocBuilder<UserProfileCubit, UserProfileState>(
                          builder: (context, userState) {
                            final profile = userState.profile;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _TopBar(
                                  onEdit: () =>
                                      showEditProfileDialog(context, userCubit),
                                  onFollowing: profile == null
                                      ? null
                                      : () => openFollows(
                                          profile.id,
                                          FollowListKind.following,
                                        ),
                                ),
                                const SizedBox(height: 26),
                                if (userState.failed)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: TextButton(
                                      onPressed: userCubit.load,
                                      child: Text(l.accLoadError),
                                    ),
                                  )
                                else
                                  ProfileHeader(
                                    profile: profile,
                                    onAvatarTap: () => showEditProfileDialog(
                                      context,
                                      userCubit,
                                    ),
                                    onBioTap: () => showEditProfileDialog(
                                      context,
                                      userCubit,
                                    ),
                                    onFollowingTap: profile == null
                                        ? null
                                        : () => openFollows(
                                            profile.id,
                                            FollowListKind.following,
                                          ),
                                    onFollowersTap: profile == null
                                        ? null
                                        : () => openFollows(
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
                                                showSection(_Section.listings),
                                          ),
                                        ),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _TopAction(
                                        icon: AppIcons.pro,
                                        label: l.accProPlan,
                                        onTap: () =>
                                            context.push(PlansView.path),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _TopAction(
                                        icon: AppIcons.store,
                                        label: l.accCreateStore,
                                        onTap: () => showComingSoon(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    _SectionTab(
                                      label: l.accListings,
                                      selected: section == _Section.listings,
                                      onTap: () =>
                                          showSection(_Section.listings),
                                    ),
                                    _SectionTab(
                                      label: l.accPosts,
                                      selected: section == _Section.posts,
                                      onTap: profile == null
                                          ? null
                                          : () => showSection(_Section.posts),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    if (section == _Section.listings)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver:
                            BlocBuilder<
                              AccountListingsCubit,
                              AccountListingsState
                            >(
                              builder: (context, state) => SliverMainAxisGroup(
                                slivers: accountListingSlivers(state),
                              ),
                            ),
                      )
                    else if (posts != null)
                      ProfilePostsSliver(cubit: posts!),
                    const SliverToBoxAdapter(child: SizedBox(height: 125)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onEdit, this.onFollowing});
  final VoidCallback onEdit;
  final VoidCallback? onFollowing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        IconButton(
          tooltip: l.accEditPage,
          onPressed: onEdit,
          icon: const Icon(
            AppIcons.edit,
            color: AppColors.textPrimary,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Text(
            'R',
            style: TextStyle(
              fontFamily: profileFontFamily,
              color: AppColors.surface,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: l.accActivity,
          onPressed: () => showComingSoon(context),
          icon: const Icon(
            AppIcons.activity,
            color: AppColors.textPrimary,
            size: 25,
          ),
        ),
        IconButton(
          tooltip: l.accFollowing,
          onPressed: onFollowing,
          icon: const Icon(
            AppIcons.followUser,
            color: AppColors.textPrimary,
            size: 25,
          ),
        ),
        IconButton(
          tooltip: l.accMenu,
          onPressed: () => showAccountMenu(context),
          icon: const Icon(
            AppIcons.menu,
            color: AppColors.textPrimary,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.circular(28),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: AppColors.textPrimary),
            const SizedBox(width: 9),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: profileFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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
    child: Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.textPrimary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: profileFontFamily,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    ),
  );
}
