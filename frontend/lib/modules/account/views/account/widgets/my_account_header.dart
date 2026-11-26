import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/profile_models.dart';
import '../../../widgets/profile_header.dart';

/// Đầu trang "Tài khoản của tôi": avatar bên trái có nút "Xem trang" mở hồ
/// sơ công khai, bên phải @username + tên + đánh giá; dưới là số liệu theo
/// dõi / tin đăng và giới thiệu
class MyAccountHeader extends StatelessWidget {
  const MyAccountHeader({
    super.key,
    required this.profile,
    required this.extraStat,
    this.onViewProfile,
    this.onRatingTap,
    this.onBioTap,
    this.onFollowingTap,
    this.onFollowersTap,
  });

  final ProfileData? profile;
  final Widget extraStat;
  final VoidCallback? onViewProfile, onRatingTap, onBioTap;
  final VoidCallback? onFollowingTap, onFollowersTap;

  static const _avatarRadius = 44.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profile = this.profile;
    final name = profile?.fullName ?? l.accLoading;
    final bio = profile?.bio?.trim();
    final rated = (profile?.ratingCount ?? 0) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              key: const ValueKey('account-view-profile'),
              onTap: onViewProfile,
              child: SizedBox(
                width: _avatarRadius * 2 + 6,
                height: _avatarRadius * 2 + 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    ProfileAvatar(
                      radius: _avatarRadius,
                      url: profile?.avatarUrl,
                      initials: ProfileHeader.initials(name),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xe6222222),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.productSellerProfile,
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: profileFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile == null ? name : '@${profile.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: profileFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: profileFontFamily,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onRatingTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.star,
                            size: 16,
                            color: rated
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              rated
                                  ? l.accRating(
                                      profile.ratingAverage.toStringAsFixed(1),
                                      profile.ratingCount,
                                    )
                                  : l.accNoRating,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: profileFontFamily,
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Icon(
                            AppIcons.chevronRight,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: ProfileStat(
                  // Theo dõi shop = theo dõi chủ shop, nên shop đã nằm trong số này
                  value: '${profile?.followingCount ?? 0}',
                  label: l.accFollowing,
                  onTap: onFollowingTap,
                ),
              ),
              Expanded(
                child: ProfileStat(
                  value: '${profile?.followerCount ?? 0}',
                  label: l.accFollowers,
                  onTap: onFollowersTap,
                ),
              ),
              Expanded(child: extraStat),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onBioTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Text(
                bio == null || bio.isEmpty ? l.accAddBio : bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: profileFontFamily,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
