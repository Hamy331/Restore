import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/feeds/bloc/feeds/feeds_cubit.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

class SellerActivityPreview extends StatelessWidget {
  const SellerActivityPreview({super.key, required this.open});
  final VoidCallback open;
  @override
  Widget build(BuildContext context) {
    final posts = context.watch<FeedsCubit>().state.posts.take(5).toList();
    if (posts.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        ListTile(
          title: Text(
            l.accActivity,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: TextButton(onPressed: open, child: Text(l.homeSeeAll)),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final post = posts[i];
              return SizedBox(
                width: 220,
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xffe5e5e5)),
                  ),
                  child: InkWell(
                    onTap: open,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (post.image != null)
                          AppLocalImage(path: post.image!, height: 86),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.author.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  TimeAgoFormatter.format(post.createdAt, l),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Expanded(
                                  child: Text(
                                    post.text,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: post.image == null ? 5 : 2,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.thumb_up_outlined,
                                      size: 15,
                                    ),
                                    Text(' ${post.likes}     '),
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 15,
                                    ),
                                    Text(' ${post.commentCount}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
