import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_opening_status.dart';

/// Tab Giới thiệu: lời giới thiệu, nhãn (Đối tác, đã xác minh) và thông tin
/// tài khoản (ngày tham gia, người theo dõi, tin đăng, địa chỉ, giờ mở cửa)
class ProfileAbout extends StatefulWidget {
  const ProfileAbout({
    super.key,
    required this.profile,
    required this.followerCount,
    this.onFollowers,
    this.onFollowing,
  });

  final ProfileData profile;
  final int followerCount;
  final VoidCallback? onFollowers, onFollowing;

  @override
  State<ProfileAbout> createState() => _ProfileAboutState();
}

class _ProfileAboutState extends State<ProfileAbout>
    with AutomaticKeepAliveClientMixin {
  bool _expanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = widget.profile, s = p.storefront;
    final l = AppLocalizations.of(context)!;
    final text =
        ((s.description ?? '').trim().isNotEmpty ? s.description : p.bio)
            ?.trim();
    const heading = TextStyle(fontSize: 17, fontWeight: FontWeight.w800);
    final long = (text?.length ?? 0) > 180;
    return ListView(
      key: const ValueKey('profile-about'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Text(l.profAbout, style: heading),
        const SizedBox(height: 10),
        Text(
          (text ?? '').isEmpty ? l.profNoAbout : text!,
          maxLines: _expanded ? null : 5,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: (text ?? '').isEmpty
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        if (long)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? l.profLess : l.profMore,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (s.isShop) ...[
          const SizedBox(height: 14),
          _Row(
            key: const ValueKey('about-partner'),
            icon: AppIcons.store,
            color: const Color(0xFFE8590C),
            title: l.profPartnerTitle,
            subtitle: l.profPartnerBody,
          ),
          if (s.verified)
            _Row(
              key: const ValueKey('about-verified'),
              icon: AppIcons.verified,
              color: AppColors.actionPrimary,
              title: s.verificationType == 'OFFICIAL_BRAND'
                  ? l.profOfficialTitle
                  : l.profVerifiedTitle,
              subtitle: l.profVerifiedBody,
            ),
        ],
        const SizedBox(height: 22),
        Text(l.profAccountDetails, style: heading),
        const SizedBox(height: 6),
        if (p.joined != null)
          _Row(
            icon: AppIcons.calendar,
            title: l.productSellerJoined(
              DateFormat.yMMM(l.localeName).format(p.joined!.toLocal()),
            ),
          ),
        _Row(
          icon: AppIcons.user,
          title: l.profFollowers(widget.followerCount),
          onTap: widget.onFollowers,
        ),
        _Row(
          icon: Icons.person_outline,
          title: l.profFollowing(p.followingCount),
          onTap: widget.onFollowing,
        ),
        _Row(icon: AppIcons.listings, title: l.profSelling(s.listings, s.sold)),
        if ((s.address ?? '').trim().isNotEmpty)
          _Row(icon: AppIcons.location, title: s.address!.trim()),
        if (s.openingHours.isNotEmpty)
          _Row(
            icon: AppIcons.clock,
            title: l.msHoursSection,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShopOpeningStatus(hours: s.openingHours),
                  for (final day in s.openingHours)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${l.shopWeekday('${day.day}')}: ${day.open} – ${day.close}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (p.lastActive != null)
          _Row(
            icon: Icons.circle,
            iconSize: 10,
            color: p.online ? AppColors.success : AppColors.textSecondary,
            title:
                '${l.sellerActivity} · ${TimeAgoFormatter.format(p.lastActive!, l)}',
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = AppColors.textSecondary,
    this.iconSize = 22,
    this.onTap,
    this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final double iconSize;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: 22,
            child: Icon(icon, size: iconSize, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ?child,
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    ),
  );
}
