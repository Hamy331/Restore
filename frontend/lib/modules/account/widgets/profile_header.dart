import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../models/profile_models.dart';

const profileFontFamily = 'DM Sans';

/// Tên, ảnh, đánh giá, số liệu và giới thiệu; dùng cho cả hồ sơ của mình
/// và hồ sơ người khác.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.onAvatarTap,
    this.onBioTap,
    this.onFollowingTap,
    this.onFollowersTap,
    this.extraStat,
    this.action,
    this.countFollowedShops = false,
  });

  /// `null` khi đang tải lần đầu.
  final ProfileData? profile;
  final VoidCallback? onAvatarTap, onBioTap, onFollowingTap, onFollowersTap;

  /// Ô số liệu thứ ba (ví dụ số tin đăng).
  final Widget? extraStat;

  /// Nút hành động dưới phần giới thiệu (ví dụ Theo dõi).
  final Widget? action;

  /// Hồ sơ của mình: "Đang theo dõi" tính cả shop đang theo dõi
  final bool countFollowedShops;

  static String initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase())
      .take(2)
      .join();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profile = this.profile;
    final name = profile?.fullName ?? l.accLoading;
    final bio = profile?.bio?.isNotEmpty == true ? profile!.bio! : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: profileFontFamily,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '@${profile?.username ?? ''}',
                    style: const TextStyle(
                      fontFamily: profileFontFamily,
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 6),
                    _Rating(profile: profile),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Avatar(
              profile: profile,
              initials: initials(name),
              onTap: onAvatarTap,
            ),
          ],
        ),
        const SizedBox(height: 23),
        Row(
          children: [
            Expanded(
              child: ProfileStat(
                value:
                    '${(profile?.followingCount ?? 0) + (countFollowedShops ? profile?.followingShopCount ?? 0 : 0)}',
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
            Expanded(child: extraStat ?? const SizedBox()),
          ],
        ),
        if (bio != null || onBioTap != null) ...[
          const SizedBox(height: 23),
          Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onBioTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Text(
                  bio ?? l.accAddBio,
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
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.profile});
  final ProfileData profile;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rated = profile.ratingCount > 0;
    return Row(
      children: [
        Icon(
          AppIcons.star,
          size: 15,
          color: rated ? AppColors.primary : AppColors.textSecondary,
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
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.initials, this.onTap});
  final ProfileData? profile;
  final String initials;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final url = profile?.avatarUrl;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.background,
            foregroundImage: url != null ? NetworkImage(url) : null,
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: profileFontFamily,
                fontSize: 27,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onTap != null)
            Positioned(
              right: -3,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(
                  AppIcons.add,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: profileFontFamily,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: profileFontFamily,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
