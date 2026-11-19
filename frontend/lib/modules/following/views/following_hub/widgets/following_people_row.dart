import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/feeds/widgets/feed_shared.dart';

/// Hàng ảnh đại diện những người mình đang theo dõi
class FollowingPeopleRow extends StatelessWidget {
  const FollowingPeopleRow({
    super.key,
    required this.people,
    required this.onTap,
  });

  final List<FollowUser> people;
  final ValueChanged<FollowUser> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 84,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: people.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final user = people[index];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap(user),
          child: SizedBox(
            width: 64,
            child: Column(
              children: [
                const SizedBox(height: 4),
                FeedAvatar(
                  name: user.fullName,
                  avatarUrl: user.avatarUrl,
                  size: 50,
                ),
                const SizedBox(height: 6),
                Text(
                  user.fullName.split(' ').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
