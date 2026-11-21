import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/widgets/profile_header.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

const storefrontOrange = Color(0xffcd520d);

String storefrontName(ProfileData p) => [
  p.storefront.name,
  p.fullName,
  p.username,
].whereType<String>().firstWhere((s) => s.trim().isNotEmpty, orElse: () => '—');

class SellerProfileSummary extends StatelessWidget {
  const SellerProfileSummary({
    super.key,
    required this.profile,
    required this.showShopLogo,
    required this.following,
    required this.followerCount,
    required this.onFollow,
    required this.onReviews,
    required this.onFollowers,
    required this.onFollowing,
    this.onCatalog,
    this.onCall,
  });
  final ProfileData profile;
  final bool showShopLogo;
  final bool following;
  final int followerCount;
  final VoidCallback? onFollow, onCatalog, onFollowers, onCall;
  final VoidCallback onReviews, onFollowing;

  @override
  Widget build(BuildContext context) {
    final p = profile, s = p.storefront, l = AppLocalizations.of(context)!;
    final name = storefrontName(p);
    final avatar = showShopLogo ? s.logo ?? p.avatarUrl : p.avatarUrl;
    final description = (s.description ?? '').trim().isNotEmpty
        ? s.description
        : p.bio;
    final since = p.joined;
    final active = p.lastActive;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.cover != null)
          AspectRatio(aspectRatio: 2.1, child: AppLocalImage(path: s.cover!)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    radius: 30,
                    url: avatar,
                    initials: ProfileHeader.initials(
                      showShopLogo ? name : p.fullName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (s.isShop || s.isPro)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Icon(
                                  s.isShop
                                      ? Icons.storefront_outlined
                                      : Icons.workspace_premium_outlined,
                                  size: 16,
                                  color: storefrontOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.isShop ? l.planShop : l.planBasic,
                                  style: theme.labelMedium?.copyWith(
                                    color: storefrontOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (active != null)
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 7,
                                color: p.online ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${l.sellerActivity} · ${TimeAgoFormatter.format(active, l)}',
                                  style: theme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Stat(l.accListings, s.listings),
                  _Stat(l.sellerSold, s.sold),
                  InkWell(
                    onTap: onFollowers,
                    child: _Stat(l.accFollowers, followerCount),
                  ),
                  InkWell(
                    onTap: onFollowing,
                    child: _Stat(l.accFollowing, p.followingCount),
                  ),
                ],
              ),
              if (since != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.productSellerJoined(
                      DateFormat.yMMM(l.localeName).format(since.toLocal()),
                    ),
                    style: theme.bodySmall,
                  ),
                ),
              InkWell(
                onTap: onReviews,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffb000),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      if (p.ratingCount > 0)
                        Text(
                          '${p.ratingAverage.toStringAsFixed(1)}  ',
                          style: theme.titleSmall,
                        ),
                      Flexible(
                        child: Text(
                          p.ratingCount > 0
                              ? l.reviewCount(p.ratingCount)
                              : l.productSellerNoReviews,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if ((s.address ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 19),
                      const SizedBox(width: 5),
                      Expanded(child: Text(s.address!)),
                    ],
                  ),
                ),
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
              if (onCall != null)
                SizedBox(
                  width: double.infinity,
                  child: SellerCallButton(onPressed: onCall!),
                ),
              if ((description ?? '').trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xfff6f6f6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.isShop ? l.msDescription : l.accBio,
                        style: theme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(description!),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
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

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.count);
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$label: '),
        TextSpan(
          text: '$count',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
