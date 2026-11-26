import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../models/profile_models.dart';
import '../../../widgets/profile_header.dart';
import '../../public_profile/seller_profile_summary.dart';

/// Thẻ hồ sơ ở đầu trang đánh giá, xoay 180° quanh trục dọc:
/// - mặt trước: logo, tên, điểm đánh giá, số đơn đã bán, thời gian ở ReStore,
///   dải dưới "Xem thông tin liên hệ" (chỉ cửa hàng)
/// - mặt sau: tên, @username, logo, nhãn doanh nghiệp đã xác minh, dải dưới
///   "Quay lại thông tin hồ sơ"
/// [showBack] do trang điều khiển (đồng bộ với tab Liên hệ).
class ProfileFlipCard extends StatefulWidget {
  const ProfileFlipCard({
    super.key,
    required this.profile,
    required this.showBack,
    this.onFlip,
  });

  final ProfileData profile;
  final bool showBack;

  /// Bấm dải dưới thẻ; null = không lật được (người dùng thường)
  final ValueChanged<bool>? onFlip;

  static const _bodyHeight = 160.0, _stripHeight = 52.0;

  @override
  State<ProfileFlipCard> createState() => _ProfileFlipCardState();
}

class _ProfileFlipCardState extends State<ProfileFlipCard>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: widget.showBack ? 1 : 0,
  );
  late final _curve = CurvedAnimation(
    parent: _turn,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(ProfileFlipCard old) {
    super.didUpdateWidget(old);
    if (old.showBack != widget.showBack) {
      widget.showBack ? _turn.forward() : _turn.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flippable = widget.onFlip != null;
    final height =
        ProfileFlipCard._bodyHeight +
        (flippable ? ProfileFlipCard._stripHeight : 0);
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final angle = _curve.value * math.pi;
          final back = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: back
                // Mặt sau xoay thêm 180° để chữ không bị ngược
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _Face(
                      key: const ValueKey('flip-back'),
                      strip: flippable
                          ? _Strip(
                              key: const ValueKey('flip-to-front'),
                              icon: Icons.undo_rounded,
                              label: AppLocalizations.of(
                                context,
                              )!.revBackToProfile,
                              onTap: () => widget.onFlip!(false),
                            )
                          : null,
                      background: const [Color(0xffd7e6f7), Color(0xffeef5fc)],
                      child: _Back(profile: widget.profile),
                    ),
                  )
                : _Face(
                    key: const ValueKey('flip-front'),
                    strip: flippable
                        ? _Strip(
                            key: const ValueKey('flip-to-back'),
                            icon: Icons.visibility_outlined,
                            label: AppLocalizations.of(context)!.revViewContact,
                            onTap: () => widget.onFlip!(true),
                          )
                        : null,
                    background: const [Color(0xfff7f7f9), Color(0xffeef0f6)],
                    child: _Front(profile: widget.profile),
                  ),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    super.key,
    required this.child,
    required this.background,
    this.strip,
  });
  final Widget child;
  final List<Color> background;
  final Widget? strip;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          SizedBox(
            height: ProfileFlipCard._bodyHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: background,
                    ),
                  ),
                ),
                // Vệt sáng trang trí góc phải
                Positioned(
                  right: -40,
                  top: -30,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.all(18), child: child),
              ],
            ),
          ),
          ?strip,
        ],
      ),
    ),
  );
}

class _Strip extends StatelessWidget {
  const _Strip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xfff6f6f6),
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: ProfileFlipCard._stripHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.actionPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.actionPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Front extends StatelessWidget {
  const _Front({required this.profile});
  final ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!, p = profile, s = p.storefront;
    final theme = Theme.of(context).textTheme;
    final name = storefrontName(p);
    Widget stat(Widget value, String label) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          value,
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
    final bold = theme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Logo(profile: p, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
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
                            size: 20,
                            color: AppColors.actionPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            stat(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.ratingCount > 0
                        ? p.ratingAverage.toStringAsFixed(1)
                        : '—',
                    style: bold,
                  ),
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
              l.reviewCount(p.ratingCount),
            ),
            stat(Text('${s.sold}', style: bold), l.revOrders),
            if (p.joined != null)
              stat(
                Text(profileTenure(l, p.joined!), style: bold),
                l.profOnRestore,
              ),
          ],
        ),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.profile});
  final ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!, p = profile;
    final theme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storefrontName(p),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (p.username.isNotEmpty)
                Text(
                  '@${p.username}',
                  style: theme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const Spacer(),
              if (p.storefront.verified)
                Row(
                  children: [
                    const Icon(
                      AppIcons.verified,
                      size: 22,
                      color: AppColors.actionPrimary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l.revVerifiedBusiness,
                        style: theme.bodyLarge,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(child: _Logo(profile: p, size: 84, round: true)),
        ),
      ],
    );
  }
}

/// Logo shop (hoặc avatar người dùng thường)
class _Logo extends StatelessWidget {
  const _Logo({required this.profile, required this.size, this.round = false});
  final ProfileData profile;
  final double size;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final p = profile, s = p.storefront;
    final url = s.isShop ? s.logo ?? p.avatarUrl : p.avatarUrl;
    if (!s.isShop || url == null || url.trim().isEmpty) {
      return ProfileAvatar(
        radius: size / 2,
        url: p.avatarUrl,
        initials: ProfileHeader.initials(storefrontName(p)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(round ? size : 10),
      child: SizedBox.square(
        dimension: size,
        child: AppLocalImage(path: url),
      ),
    );
  }
}
