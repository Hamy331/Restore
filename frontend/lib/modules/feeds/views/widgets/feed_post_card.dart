import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_local_image.dart';
import '../../bloc/feeds_cubit.dart';
import 'feed_comments_sheet.dart';
import 'feed_image_viewer.dart';
import 'feed_shared.dart';

/// Mở trang hồ sơ của tác giả; bài của mình thì về tab Tài khoản.
void openFeedAuthor(BuildContext context, FeedPost post) => post.isMine
    ? context.go('/account')
    : context.push('/users/${post.authorId}');

Future<void> _postMenu(BuildContext context, FeedsCubit cubit, FeedPost post) {
  final l = AppLocalizations.of(context)!;
  final following = cubit.state.following.contains(post.authorId);
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (post.isMine)
          ListTile(
            leading: const Icon(AppIcons.delete, color: AppColors.error),
            title: Text(
              l.feedDelete,
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(sheet);
              _confirmDelete(context, cubit, post);
            },
          )
        else ...[
          ListTile(
            leading: const Icon(AppIcons.followUser),
            title: Text(following ? l.feedUnfollow : l.feedFollow),
            onTap: () {
              Navigator.pop(sheet);
              cubit.toggleFollow(post.authorId);
            },
          ),
          if (cubit.authorId == null)
            ListTile(
              leading: const Icon(AppIcons.user),
              title: Text(l.feedViewProfile),
              onTap: () {
                Navigator.pop(sheet);
                openFeedAuthor(context, post);
              },
            ),
          ListTile(
            leading: const Icon(AppIcons.report),
            title: Text(l.feedReport),
            onTap: () {
              Navigator.pop(sheet);
              _report(context, cubit, post);
            },
          ),
        ],
      ],
    ),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  FeedsCubit cubit,
  FeedPost post,
) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      content: Text(l.feedDeleteConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialog, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(l.feedDelete),
        ),
      ],
    ),
  );
  if (confirmed == true && await cubit.delete(post) && context.mounted) {
    feedNotice(context, l.feedDeleted);
  }
}

Future<void> _report(
  BuildContext context,
  FeedsCubit cubit,
  FeedPost post,
) async {
  final l = AppLocalizations.of(context)!;
  final reason = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l.feedReportTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final reason in [
          l.feedReportSpam,
          l.feedReportScam,
          l.feedReportOffensive,
          l.feedReportOther,
        ])
          ListTile(
            title: Text(reason),
            onTap: () => Navigator.pop(sheet, reason),
          ),
      ],
    ),
  );
  if (reason != null && await cubit.report(post, reason) && context.mounted) {
    feedNotice(context, l.feedReported);
  }
}

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post, required this.cubit});
  final FeedPost post;
  final FeedsCubit cubit;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = post.author.name.isEmpty && post.isMine
        ? l.feedYourName
        : post.author.name;
    // Trên trang hồ sơ, bài nào cũng là của người đang xem nên không mở lại.
    final onAuthorTap = cubit.authorId == null
        ? () => openFeedAuthor(context, post)
        : null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: onAuthorTap,
                child: FeedAvatar(name: name, avatarUrl: post.author.avatarUrl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onAuthorTap,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feedTime(l, post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).showMenuTooltip,
                        icon: const Icon(AppIcons.moreHorizontal, size: 18),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _postMenu(context, cubit, post),
                      ),
                    ],
                  ),
                  if (post.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        post.text,
                        style: const TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  if (post.image != null)
                    GestureDetector(
                      onTap: () => showFeedImage(
                        context,
                        post.image!,
                        heroTag: 'feed-image-${post.id}',
                      ),
                      child: Hero(
                        tag: 'feed-image-${post.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 360),
                            child: AppLocalImage(
                              path: post.image!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              cacheWidth: 900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _LikePill(post: post, cubit: cubit),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: l.feedComments,
                        child: _Pill(
                          onTap: () => showFeedComments(context, cubit, post),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.chat, size: 17),
                              if (post.commentCount > 0) ...[
                                const SizedBox(width: 6),
                                Semantics(
                                  label: l.feedCommentCount(post.commentCount),
                                  child: Text(
                                    '${post.commentCount}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 29, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        child: child,
      ),
    ),
  );
}

class _LikePill extends StatelessWidget {
  const _LikePill({required this.post, required this.cubit});
  final FeedPost post;
  final FeedsCubit cubit;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Tooltip(
      message: post.liked ? l.feedUnlike : l.feedLike,
      child: _Pill(
        onTap: () => cubit.toggleLike(post),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              post.liked ? AppIcons.favoriteActive : AppIcons.favorite,
              size: 17,
              color: post.liked ? AppColors.error : null,
            ),
            const SizedBox(width: 6),
            Text(l.feedLike, style: const TextStyle(fontSize: 12)),
            if (post.likes > 0) ...[
              const SizedBox(
                height: 16,
                child: VerticalDivider(width: 17, color: AppColors.border),
              ),
              Semantics(
                label: l.feedLikes(post.likes),
                child: Text(
                  '${post.likes}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
