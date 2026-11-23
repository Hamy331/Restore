import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/widgets/profile_header.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/listing/listing_partner_badge.dart';

const storefrontOrange = Color(0xffcd520d);

String storefrontName(ProfileData p) => [
  p.storefront.name,
  p.fullName,
  p.username,
].whereType<String>().firstWhere((s) => s.trim().isNotEmpty, orElse: () => '—');

/// Thời gian đã ở ReStore: "2 năm", "5 tháng", "12 ngày"
String profileTenure(AppLocalizations l, DateTime joined, [DateTime? now]) {
  final at = now ?? DateTime.now();
  final start = joined.toLocal();
  final months =
      (at.year - start.year) * 12 +
      at.month -
      start.month -
      (at.day < start.day ? 1 : 0);
  if (months >= 12) return l.profYears(months ~/ 12);
  if (months >= 1) return l.profMonths(months);
  final days = at.difference(start).inDays;
  return l.profDays(days < 1 ? 1 : days);
}

/// Đầu trang hồ sơ: ảnh bìa (cửa hàng dùng ảnh bìa shop, người dùng thường là
/// một màu), avatar ở giữa, tên kèm dấu xác minh và nhãn Đối tác, @username,
/// điểm đánh giá và thời gian ở ReStore, rồi các nút theo dõi / liên hệ
class SellerProfileSummary extends StatelessWidget {
  const SellerProfileSummary({
    super.key,
    required this.profile,
    required this.showShopLogo,
    required this.following,
    required this.onFollow,
    required this.onReviews,
    this.onCatalog,
    this.onCall,
    this.onChat,
  });
  final ProfileData profile;
  final bool showShopLogo;
  final bool following;
  final VoidCallback? onFollow, onCatalog, onCall;

  /// Desktop: nút Nhắn tin nằm cạnh nút Gọi trong thẻ (không có thanh dưới)
  final VoidCallback? onChat;
  final VoidCallback onReviews;

  static const coverHeight = 120.0;
  static const avatarRadius = 44.0;

  @override
  Widget build(BuildContext context) {
    final p = profile, s = p.storefront, l = AppLocalizations.of(context)!;
    final name = storefrontName(p);
    final avatar = s.isShop && (showShopLogo || p.avatarUrl == null)
        ? s.logo ?? p.avatarUrl
        : p.avatarUrl;
    final since = p.joined;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: coverHeight + avatarRadius,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: coverHeight,
                child: s.isShop && s.cover != null
                    ? AppLocalImage(
                        key: const ValueKey('profile-cover-image'),
                        path: s.cover!,
                      )
                    : const ColoredBox(
                        key: ValueKey('profile-cover-plain'),
                        color: AppColors.primary,
                      ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: ProfileAvatar(
                    radius: avatarRadius,
                    url: avatar,
                    initials: ProfileHeader.initials(
                      s.isShop ? name : p.fullName,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: name),
                    if (s.verified)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            AppIcons.verified,
                            key: ValueKey('profile-verified'),
                            size: 20,
                            color: AppColors.actionPrimary,
                          ),
                        ),
                      ),
                    if (s.isShop)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: ListingPartnerBadge(
                            key: ValueKey('profile-partner'),
                          ),
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (p.username.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '@${p.username}',
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      key: const ValueKey('profile-rating'),
                      onTap: onReviews,
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.ratingCount > 0
                                ? p.ratingAverage.toStringAsFixed(1)
                                : '—',
                            style: theme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ],
                      ),
                      label: p.ratingCount > 0
                          ? l.reviewCount(p.ratingCount)
                          : l.productSellerNoReviews,
                    ),
                  ),
                  if (since != null)
                    Expanded(
                      child: _HeaderStat(
                        key: const ValueKey('profile-tenure'),
                        value: Text(
                          profileTenure(l, since),
                          style: theme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        label: l.profOnRestore,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (onFollow != null || onCatalog != null)
                Row(
                  children: [
                    if (onFollow != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onFollow,
                          icon: Icon(
                            following
                                ? Icons.check
                                : Icons.person_add_alt_1_outlined,
                            size: 18,
                          ),
                          label: Text(
                            following ? l.feedUnfollow : l.feedFollow,
                          ),
                        ),
                      ),
                    if (onCatalog != null) ...[
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: l.shopDetailProductsTitle,
                        onPressed: onCatalog,
                        icon: const Icon(Icons.storefront_outlined),
                      ),
                    ],
                  ],
                ),
              if (onChat != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: onChat,
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: Text(l.productChat),
                        ),
                      ),
                      if (onCall != null) ...[
                        const SizedBox(width: 8),
                        Expanded(child: SellerCallButton(onPressed: onCall!)),
                      ],
                    ],
                  ),
                )
              else if (onCall != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: SellerCallButton(onPressed: onCall!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });
  final Widget value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          value,
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class SellerCallButton extends StatelessWidget {
  const SellerCallButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: storefrontOrange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    onPressed: onPressed,
    icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
    label: Text(AppLocalizations.of(context)!.listingCall),
  );
}
