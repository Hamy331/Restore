import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/feeds/feeds_cubit.dart';
import '../bloc/feeds/feeds_state.dart';
import 'feed_post_card.dart';

/// Các sliver hiển thị bài viết, trạng thái tải thêm và nút thử lại.
/// Dùng chung cho bảng tin và trang hồ sơ.
List<Widget> feedPostSlivers(FeedsCubit cubit, FeedsState state) => [
  SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) => RepaintBoundary(
        child: FeedPostCard(post: state.posts[index], cubit: cubit),
      ),
      childCount: state.posts.length,
    ),
  ),
  if (state.loadingMore)
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    )
  else if (state.loadMoreFailed)
    SliverToBoxAdapter(child: _LoadMoreRetry(cubit: cubit)),
];

/// Gọi [FeedsCubit.loadMore] khi còn cách cuối danh sách dưới 300px.
bool feedScrollListener(FeedsCubit cubit, ScrollNotification n) {
  if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 300) {
    cubit.loadMore();
  }
  return false;
}

class _LoadMoreRetry extends StatelessWidget {
  const _LoadMoreRetry({required this.cubit});
  final FeedsCubit cubit;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(l.feedLoadMoreError, textAlign: TextAlign.center),
          TextButton(
            onPressed: () => cubit.loadMore(retry: true),
            child: Text(l.retry),
          ),
        ],
      ),
    );
  }
}
