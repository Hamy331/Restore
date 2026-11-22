import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/app_image_provider.dart';
import '../models/profile_models.dart';

const profileFontFamily = 'DM Sans';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.radius,
    required this.url,
    required this.initials,
  });

  final double radius;
  final String? url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final path = url?.trim();
    // Ảnh mạng có cache đĩa (appImageProvider), ảnh assets dùng thẳng
    final ImageProvider? image = path == null || path.isEmpty
        ? null
        : appImageProvider(path);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.fill,
      foregroundImage: image,
      onForegroundImageError: image == null ? null : (_, _) {},
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: profileFontFamily,
          fontSize: radius * 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

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
    this.onRatingTap,
    this.extraStat,
    this.action,
  });

  /// `null` khi đang tải lần đầu.
  final ProfileData? profile;
  final VoidCallback? onAvatarTap, onBioTap, onFollowingTap, onFollowersTap;
  final VoidCallback? onRatingTap;

  /// Ô số liệu thứ ba (ví dụ số tin đăng).
  final Widget? extraStat;

  /// Nút hành động dưới phần giới thiệu (ví dụ Theo dõi).
  final Widget? action;

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
                    InkWell(
                      onTap:
                          onRatingTap ??
                          () =>
                              context.push('/users/${profile.id}?tab=reviews'),
                      child: _Rating(
                        profile: profile,
                        showChevron: onRatingTap != null,
                      ),
                    ),
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
            Expanded(child: extraStat ?? const SizedBox()),
          ],
        ),
        if (bio != null || onBioTap != null) ...[
          const SizedBox(height: 23),
          Material(
            color: AppColors.fill,
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
  const _Rating({required this.profile, required this.showChevron});
  final ProfileData profile;
  final bool showChevron;
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
        if (showChevron) const Icon(AppIcons.chevronRight, size: 14),
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
          ProfileAvatar(radius: 45, url: url, initials: initials),
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
