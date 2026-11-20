import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/shared/widgets/app_image_icon.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../../bloc/feeds/feeds_cubit.dart';
import '../../bloc/feeds/feeds_state.dart';
import '../../widgets/feed_post_list.dart';
import '../../widgets/feed_shared.dart';
import 'widgets/feed_composer.dart';

/// Bảng tin trên web desktop, 3 cột như các mạng xã hội:
/// menu trái (hồ sơ + lối tắt), luồng bài viết ở giữa, gợi ý bên phải.
/// Luồng bài dùng lại [feedPostSlivers] của bản điện thoại.
class FeedsDesktopView extends StatelessWidget {
  const FeedsDesktopView({super.key});

  static const double _side = 270;
  static const double _gap = 20;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FeedsCubit>();
    final showRight = MediaQuery.sizeOf(context).width >= 1280;
    return BlocConsumer<FeedsCubit, FeedsState>(
      listener: (context, state) {
        if (state.error != null) feedNotice(context, l.feedActionError);
      },
      builder: (context, state) => NotificationListener<ScrollNotification>(
        onNotification: (n) => feedScrollListener(cubit, n),
        child: DesktopPage(
          slivers: [
            SliverCrossAxisGroup(
              slivers: [
                SliverConstrainedCrossAxis(
                  maxExtent: _side,
                  sliver: SliverToBoxAdapter(child: _LeftMenu(state: state)),
                ),
                const SliverConstrainedCrossAxis(
                  maxExtent: _gap,
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverCrossAxisExpanded(
                  flex: 1,
                  sliver: DecoratedSliver(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _FeedTop(cubit: cubit, state: state),
                        ),
                        if (state.loading && state.posts.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(child: AppLoadingIndicator()),
                            ),
                          )
                        else if (state.failed)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Text(l.feedLoadError),
                                  TextButton(
                                    onPressed: cubit.load,
                                    child: Text(l.retry),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (state.posts.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                state.onlyFollowing
                                    ? l.feedFollowingEmpty
                                    : l.feedEmpty,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ...feedPostSlivers(cubit, state),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],
                    ),
                  ),
                ),
                // Cột gợi ý chỉ hiện khi màn đủ rộng, cột giữa không bị hẹp
                if (showRight) ...[
                const SliverConstrainedCrossAxis(
                  maxExtent: _gap,
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverConstrainedCrossAxis(
                  maxExtent: _side,
                  sliver: SliverToBoxAdapter(
                    child: _RightPanel(cubit: cubit),
                  ),
                ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab Dành cho bạn / Đang theo dõi + ô "Bạn muốn chia sẻ điều gì?"
class _FeedTop extends StatelessWidget {
  const _FeedTop({required this.cubit, required this.state});
  final FeedsCubit cubit;
  final FeedsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget tab(String label, bool selected, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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

    return Column(
      children: [
        Row(
          children: [
            tab(l.feedForYou, !state.onlyFollowing, () => cubit.select(false)),
            tab(l.feedFollowing, state.onlyFollowing, () => cubit.select(true)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              FeedAvatar.me(state.me, fallbackName: l.feedYourName, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => showFeedComposer(context, cubit),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      l.feedCompose,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => showFeedComposer(context, cubit),
                icon: const Icon(
                  AppIcons.addPhoto,
                  size: 18,
                  color: AppColors.success,
                ),
                label: Text(
                  l.feedAddPhoto,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _LeftMenu extends StatelessWidget {
  const _LeftMenu({required this.state});
  final FeedsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final me = state.me;
    Widget item(IconData icon, String label, String path, {bool on = false}) =>
        Material(
          color: on ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => on ? null : context.push(path),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: AppColors.primaryDark),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    return DesktopBox(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.go('/account'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  FeedAvatar.me(me, fallbackName: l.feedYourName, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      me == null || me.name.isEmpty ? l.feedYourName : me.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16, color: AppColors.border),
          item(AppIcons.feeds, l.feedsTitle, '/feeds', on: true),
          item(AppIcons.following, l.homeQuickFollowing, '/following'),
          item(AppIcons.verified, l.homeQuickTrustedShops, '/trusted-shops'),
          item(AppIcons.hot, l.hotSaleTitle, '/hot-sale'),
          item(AppIcons.nearby, l.homeQuickNearby, '/nearby'),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.cubit});
  final FeedsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;

    Widget shortcut(String image, IconData fallback, String title,
            String subtitle, VoidCallback onTap) =>
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AppImageIcon(image, size: 36, fallback: fallback),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopBox(
          title: t('Chia sẻ với cộng đồng', 'Share with the community'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t(
                  'Khoe món đồ mới mua, hỏi kinh nghiệm hoặc rao nhanh món muốn bán.',
                  'Show off a find, ask for tips or tease something for sale.',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => showFeedComposer(context, cubit),
                icon: const Icon(AppIcons.post, size: 18),
                label: Text(t('Viết bài', 'Write a post')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 42),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(CreateListingStep.category.path),
                icon: const Icon(AppIcons.add, size: 18),
                label: Text(t('Đăng tin bán', 'Post a listing')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 42),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DesktopBox(
          title: t('Khám phá', 'Explore'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              shortcut(
                AppImages.uiIcons.nearby,
                AppIcons.nearby,
                l.homeQuickNearby,
                l.homeQuickNearbyDesc,
                () => context.push('/nearby'),
              ),
              shortcut(
                AppImages.uiIcons.wantedAlert,
                AppIcons.wantedAlert,
                l.homeQuickWanted,
                l.homeQuickWantedDesc,
                () => context.push('/wanted-alerts'),
              ),
              shortcut(
                AppImages.uiIcons.trustedShop,
                AppIcons.verified,
                l.homeQuickTrustedShops,
                l.homeQuickTrustedShopsDesc,
                () => context.push('/trusted-shops'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
