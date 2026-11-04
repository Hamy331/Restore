import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feeds/bloc/feeds_cubit.dart';
import '../../../feeds/views/widgets/feed_post_list.dart';
import '../../../feeds/views/widgets/feed_shared.dart';

/// Bài viết của một người trên trang hồ sơ, dùng lại thẻ bài của bảng tin.
class ProfilePostsSliver extends StatelessWidget {
  const ProfilePostsSliver({super.key, required this.cubit});
  final FeedsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<FeedsCubit, FeedsState>(
        listenWhen: (_, state) => state.error != null,
        listener: (context, _) => feedNotice(context, l.feedActionError),
        builder: (context, state) {
          if (state.loading && state.posts.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (state.failed) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Text(l.feedLoadError),
                    TextButton(onPressed: cubit.load, child: Text(l.retry)),
                  ],
                ),
              ),
            );
          }
          if (state.posts.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 44),
                child: Text(
                  l.feedEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return SliverMainAxisGroup(slivers: feedPostSlivers(cubit, state));
        },
      ),
    );
  }
}
