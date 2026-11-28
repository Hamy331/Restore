import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/shop_verification_type.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/widgets/profile_header.dart';
import 'package:restore/modules/account/widgets/profile_plain_cover.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_verification_badge.dart';
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

/// Đầu trang hồ sơ (điện thoại): bìa tràn ngang, thẻ trắng đè lên bìa (logo
/// hoặc avatar, tên, nhãn hoặc @username, đánh giá, thời gian ở ReStore,
/// Theo dõi + Chia sẻ), dưới thẻ là giới thiệu và dòng chứng nhận (shop đã
/// xác minh). Chỉ cửa hàng đặt được ảnh bìa; người dùng thường có nền màu
/// thương hiệu cố định.
class SellerProfileSummary extends StatelessWidget {
  const SellerProfileSummary({
    super.key,
    required this.profile,
    required this.showShopLogo,
    required this.following,
    required this.onFollow,
    required this.onReviews,
    this.onCall,
    this.onChat,
    this.onBack,
    this.onShare,
    this.onAbout,
    this.onCertificate,
    this.onReport,
  });
  final ProfileData profile;
  final bool showShopLogo;
  final bool following;
  final VoidCallback? onFollow, onCall;

  /// Desktop: nút Nhắn tin nằm cạnh nút Gọi trong thẻ (không có thanh dưới)
  final VoidCallback? onChat;
  final VoidCallback onReviews;

  /// Nút quay lại nổi trên ảnh bìa (điện thoại, trang không có thanh tiêu đề)
  final VoidCallback? onBack;
  final VoidCallback? onShare, onAbout, onCertificate;

  /// Báo cáo người dùng (menu ⋮ trên desktop); null ở trang của chính mình
  final VoidCallback? onReport;

  static const coverHeight = 130.0;
  static const avatarRadius = 44.0;

  @override
  Widget build(BuildContext context) => _ShopSummary(this);
}

class _ShopSummary extends StatelessWidget {
  const _ShopSummary(this.w);
  final SellerProfileSummary w;

  /// Phần thẻ đè lên ảnh bìa
  static const _overlap = 44.0;

  /// Rộng hơn mức này (desktop): bìa cao hơn, thẻ và phần giới thiệu không
  /// kéo hết chiều ngang
  static const _roomyWidth = 720.0;

  /// Từ mức này mới đủ chỗ cho thẻ ngang (tên + số liệu + các nút trên một
  /// hàng); hẹp hơn thì thẻ dọc căn giữa, tránh ép khối tên
  static const _wideWidth = 1080.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _build(context, box.maxWidth),
  );

  Widget _build(BuildContext context, double width) {
    final roomy = width > _roomyWidth, wide = width >= _wideWidth;
    final p = w.profile, s = p.storefront, l = AppLocalizations.of(context)!;
    final name = storefrontName(p);
    final logo = s.logo ?? p.avatarUrl;
    final type = ShopVerificationType.fromApi(s.verificationType);
    final theme = Theme.of(context).textTheme;
    final topInset = w.onBack == null ? 0.0 : MediaQuery.paddingOf(context).top;
    final coverHeight =
        SellerProfileSummary.coverHeight + topInset + (wide ? 30 : (roomy ? 90 : 0));
    // Cửa hàng: giới thiệu shop; người dùng thường: tiểu sử
    final description = (s.isShop ? s.description : p.bio)?.trim();
    Widget limit(double max, Widget child) => roomy
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: max),
              child: child,
            ),
          )
        : child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: coverHeight,
                  // Chỉ cửa hàng mới đặt được ảnh bìa; còn lại là nền màu
                  // thương hiệu cố định có hoạ tiết
                  child: s.isShop && s.cover != null
                      ? AppLocalImage(
                          key: const ValueKey('profile-cover-image'),
                          path: s.cover!,
                        )
                      : const ProfilePlainCover(key: ValueKey('profile-cover-plain')),
                ),
              ],
            ),
            if (w.onBack != null)
              Positioned(
                top: topInset + 8,
                left: 12,
                child: _CircleButton(
                  key: const ValueKey('profile-back'),
                  icon: AppIcons.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: w.onBack!,
                  elevated: true,
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 16,
                coverHeight - _overlap,
                wide ? 24 : 16,
                0,
              ),
              // Rộng: thẻ ngang trải hết bề rộng; hẹp hơn: thẻ dọc (căn giữa
              // khi màn rộng vừa)
              child: wide
                  ? _WideShopCard(
                      w: w,
                      name: name,
                      logo: logo,
                      type: type,
                      theme: theme,
                      l: l,
                    )
                  : limit(
                      520,
                      _ShopCard(
                        w: w,
                        name: name,
                        logo: logo,
                        type: type,
                        theme: theme,
                        l: l,
                      ),
                    ),
            ),
          ],
        ),
        if (description != null && description.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 14, wide ? 32 : 16, 0),
            child: wide
                ? _ExpandableText(
                    key: const ValueKey('profile-description'),
                    text: description,
                  )
                : limit(
                    520,
                    _ExpandableText(
                      key: const ValueKey('profile-description'),
                      text: description,
                    ),
                  ),
          ),
        if (s.verified)
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 8, 6, wide ? 24 : 8, 0),
            child: limit(
              wide ? 720 : 536,
              InkWell(
                key: const ValueKey('profile-certificate'),
                borderRadius: BorderRadius.circular(8),
                onTap: w.onCertificate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ShopVerificationStyle.of(type).icon,
                        size: 20,
                        color: ShopVerificationStyle.of(type).accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (type ?? ShopVerificationType.officialBrand).label(l),
                          style: theme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (w.onCertificate != null)
                        const Icon(
                          AppIcons.chevronRight,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.w,
    required this.name,
    required this.logo,
    required this.type,
    required this.theme,
    required this.l,
  });
  final SellerProfileSummary w;
  final String name;
  final String? logo;
  final ShopVerificationType? type;
  final TextTheme theme;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final p = w.profile, s = p.storefront;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: w.onAbout,
              child: Row(
                children: [
                  s.isShop
                      ? _ShopLogo(url: logo, name: name)
                      : ProfileAvatar(
                          radius: 32,
                          url: p.avatarUrl,
                          initials: ProfileHeader.initials(name),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: name),
                              if (s.verified)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      AppIcons.verified,
                                      key: const ValueKey('profile-verified'),
                                      size: 20,
                                      color: ShopVerificationStyle.of(
                                        type,
                                      ).accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (s.isShop)
                              const ListingPartnerBadge(
                                key: ValueKey('profile-partner'),
                              ),
                            if (s.verified && type != null)
                              ShopVerificationBadge(type: type!),
                            if (!s.isShop && p.username.isNotEmpty)
                              Text(
                                '@${p.username}',
                                style: theme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (w.onAbout != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        AppIcons.chevronRight,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _RatingStat(w: w, theme: theme, l: l),
                    ),
                    if (p.joined != null) ...[
                      const VerticalDivider(width: 1, color: Color(0xffe6e6e6)),
                      Expanded(
                        child: _TenureStat(w: w, theme: theme, l: l),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (w.onFollow != null || w.onShare != null) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    if (w.onFollow != null)
                      Expanded(
                        child: _FollowButton(w: w, l: l),
                      ),
                    if (w.onShare != null && w.onFollow != null) ...[
                      const SizedBox(width: 10),
                      _CircleButton(
                        key: const ValueKey('profile-share'),
                        icon: Icons.ios_share,
                        tooltip: l.profShare,
                        onPressed: w.onShare!,
                      ),
                      if (w.onReport != null) _MoreMenu(w: w, l: l),
                    ]
                    // Trang của mình (không có Theo dõi): nút Chia sẻ trải
                    // hết hàng thay cho nút tròn đứng lẻ
                    else if (w.onShare != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('profile-share'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: Colors.black87,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: w.onShare,
                          icon: const Icon(Icons.ios_share, size: 20),
                          label: Text(l.profShare),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            _ContactButtons(w: w, l: l, rightPadding: 8),
          ],
        ),
      ),
    );
  }
}

/// Thẻ hồ sơ trên desktop (kiểu Carousell): một hàng ngang trải hết bề rộng,
/// bên trái logo / avatar và tên kèm nhãn, ở giữa đánh giá và thời gian ở
/// ReStore, bên phải các nút Theo dõi, Nhắn tin, Gọi, Chia sẻ.
class _WideShopCard extends StatelessWidget {
  const _WideShopCard({
    required this.w,
    required this.name,
    required this.logo,
    required this.type,
    required this.theme,
    required this.l,
  });
  final SellerProfileSummary w;
  final String name;
  final String? logo;
  final ShopVerificationType? type;
  final TextTheme theme;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final p = w.profile, s = p.storefront;
    Widget action(Widget child) =>
        Padding(padding: const EdgeInsets.only(left: 10), child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: w.onAbout,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    s.isShop
                        ? _ShopLogo(url: logo, name: name)
                        : ProfileAvatar(
                            radius: 36,
                            url: p.avatarUrl,
                            initials: ProfileHeader.initials(name),
                          ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: name),
                                if (s.verified)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Icon(
                                        AppIcons.verified,
                                        key: const ValueKey('profile-verified'),
                                        size: 20,
                                        color: ShopVerificationStyle.of(
                                          type,
                                        ).accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (s.isShop)
                                const ListingPartnerBadge(
                                  key: ValueKey('profile-partner'),
                                ),
                              if (s.verified && type != null)
                                ShopVerificationBadge(type: type!),
                              if (!s.isShop && p.username.isNotEmpty)
                                Text(
                                  '@${p.username}',
                                  style: theme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (w.onAbout != null)
                                const Icon(
                                  AppIcons.chevronRight,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tên bên trái; số liệu đi cùng nhóm với các nút bên phải (kiểu
            // Carousell), mỗi ô vừa chữ nên nhãn không bị xuống dòng
            const Spacer(),
            const SizedBox(width: 24),
            IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _RatingStat(w: w, theme: theme, l: l),
                  ),
                  if (p.joined != null) ...[
                    const VerticalDivider(width: 1, color: Color(0xffe6e6e6)),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: _TenureStat(w: w, theme: theme, l: l),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            if (w.onFollow != null)
              action(
                SizedBox(width: 150, child: _FollowButton(w: w, l: l)),
              ),
            if (w.onChat != null)
              action(
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: Colors.black87,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: w.onChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(l.productChat),
                ),
              ),
            if (w.onCall != null)
              action(
                _CircleButton(
                  key: const ValueKey('profile-call'),
                  icon: Icons.phone_outlined,
                  tooltip: l.listingCall,
                  onPressed: w.onCall!,
                ),
              ),
            if (w.onShare != null)
              action(
                _CircleButton(
                  key: const ValueKey('profile-share'),
                  icon: Icons.ios_share,
                  tooltip: l.profShare,
                  onPressed: w.onShare!,
                ),
              ),
            // Menu ⋮: báo cáo người dùng (không có ở trang của mình)
            if (w.onReport != null) _MoreMenu(w: w, l: l),
          ],
        ),
      ),
    );
  }
}

class _RatingStat extends StatelessWidget {
  const _RatingStat({required this.w, required this.theme, required this.l});
  final SellerProfileSummary w;
  final TextTheme theme;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final p = w.profile;
    return _HeaderStat(
      key: const ValueKey('profile-rating'),
      onTap: w.onReviews,
      value: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.ratingCount > 0 ? p.ratingAverage.toStringAsFixed(1) : '—',
            style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, color: AppColors.primary, size: 22),
        ],
      ),
      label: p.ratingCount > 0
          ? l.reviewCount(p.ratingCount)
          : l.productSellerNoReviews,
    );
  }
}

class _TenureStat extends StatelessWidget {
  const _TenureStat({required this.w, required this.theme, required this.l});
  final SellerProfileSummary w;
  final TextTheme theme;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => _HeaderStat(
    key: const ValueKey('profile-tenure'),
    onTap: w.onAbout,
    value: Text(
      profileTenure(l, w.profile.joined!),
      style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
    label: l.profOnRestore,
  );
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.w, required this.l});
  final SellerProfileSummary w;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      foregroundColor: Colors.black87,
      shape: const StadiumBorder(),
    ),
    onPressed: w.onFollow,
    icon: Icon(w.following ? Icons.check : Icons.add, size: 20),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(w.following ? l.feedUnfollow : l.feedFollow, maxLines: 1),
    ),
  );
}

/// Nút Nhắn tin / Gọi trong thẻ (desktop có cả hai; điện thoại dùng thanh
/// dưới đáy nên không truyền)
class _ContactButtons extends StatelessWidget {
  const _ContactButtons({
    required this.w,
    required this.l,
    this.rightPadding = 0,
  });
  final SellerProfileSummary w;
  final AppLocalizations l;
  final double rightPadding;

  @override
  Widget build(BuildContext context) {
    if (w.onChat == null && w.onCall == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 8, rightPadding, 0),
      child: Row(
        children: [
          if (w.onChat != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: w.onChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(l.productChat),
              ),
            ),
          if (w.onChat != null && w.onCall != null) const SizedBox(width: 8),
          if (w.onCall != null)
            Expanded(child: SellerCallButton(onPressed: w.onCall!)),
        ],
      ),
    );
  }
}

class _ShopLogo extends StatelessWidget {
  const _ShopLogo({required this.url, required this.name});
  final String? url;
  final String name;

  static const _size = 64.0;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffeeeeee)),
      color: AppColors.fill,
    ),
    clipBehavior: Clip.antiAlias,
    child: url == null || url!.trim().isEmpty
        ? Center(
            child: Text(
              ProfileHeader.initials(name),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textSecondary,
              ),
            ),
          )
        : AppLocalImage(key: const ValueKey('profile-shop-logo'), path: url!),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.elevated = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool elevated;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: CircleBorder(
      side: elevated
          ? BorderSide.none
          : const BorderSide(color: Color(0xffd9d9d9)),
    ),
    elevation: elevated ? 2 : 0,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.black87),
    ),
  );
}

/// Đoạn giới thiệu 3 dòng, bấm "Xem thêm" để mở hết
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({super.key, required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _lines = 3;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final style = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: Colors.black87, height: 1.4);
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: box.maxWidth);
        final long = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _open ? null : _lines,
              overflow: _open ? null : TextOverflow.ellipsis,
            ),
            if (long)
              GestureDetector(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _open ? l.productReadLess : l.productReadMore,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
        mainAxisSize: MainAxisSize.min,
        children: [
          value,
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
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

/// Nút ⋮ ở thẻ hồ sơ: báo cáo người dùng (không có ở trang của mình).
/// Dùng chung cho thẻ ngang (desktop) và thẻ dọc (điện thoại).
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.w, required this.l});
  final SellerProfileSummary w;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: PopupMenuButton<void>(
      key: const ValueKey('profile-more'),
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      position: PopupMenuPosition.under,
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(AppIcons.more, color: Colors.black87),
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          key: const ValueKey('profile-report'),
          onTap: w.onReport,
          child: Row(
            children: [
              const Icon(AppIcons.report, size: 18, color: Colors.black87),
              const SizedBox(width: 10),
              Text(l.reportUser),
            ],
          ),
        ),
      ],
    ),
  );
}
