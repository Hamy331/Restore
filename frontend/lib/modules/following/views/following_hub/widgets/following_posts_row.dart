import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/feeds/models/feed_models.dart';
import 'package:restore/modules/feeds/widgets/feed_shared.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import 'following_palette.dart';

/// Hàng thẻ bài đăng mới trên Bảng tin của những người mình theo dõi
class FollowingPostsRow extends StatelessWidget {
  const FollowingPostsRow({
    super.key,
    required this.posts,
    required this.onTap,
  });

  final List<FeedPost> posts;
  final ValueChanged<FeedPost> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 196,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) => _PostCard(
        key: ValueKey('following-post-${posts[index].id}'),
        post: posts[index],
        onTap: () => onTap(posts[index]),
      ),
    ),
  );
}

class _PostCard extends StatelessWidget {
  const _PostCard({super.key, required this.post, required this.onTap});

  final FeedPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final image = post.image;
    return SizedBox(
      width: 252,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FeedAvatar(
                      name: post.author.name,
                      avatarUrl: post.author.avatarUrl,
                      size: 34,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            TimeAgoFormatter.format(post.createdAt, l),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: image == null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FollowingPalette.tint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.text,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                post.text,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 86,
                                height: 86,
                                child: AppLocalImage(
                                  path: image,
                                  cacheWidth: 260,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      post.liked ? AppIcons.favoriteActive : AppIcons.favorite,
                      size: 15,
                      color: post.liked
                          ? FollowingPalette.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likes}', style: _meta),
                    const SizedBox(width: 14),
                    const Icon(
                      AppIcons.chat,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}', style: _meta),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _meta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}
