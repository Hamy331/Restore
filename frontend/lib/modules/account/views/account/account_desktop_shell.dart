import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_bloc.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/bloc/auth/auth_event.dart';

import '../../widgets/profile_header.dart';
import 'widgets/account_menu.dart' show confirmLogout;

/// Đường dẫn thuộc nhóm "Tài khoản" trên web desktop: hiện menu bên trái
/// như trang Tài khoản của Shopee, nội dung trang nằm bên phải.
bool isAccountSectionPath(String path, {String? userId}) {
  const exact = {'/account', '/profile/edit', '/settings', '/plans', '/insights'};
  const prefixes = [
    '/credits',
    '/wanted-alerts',
    '/following',
    '/boost',
    '/my-shop',
    '/shop-posters',
    '/create-listing/drafts',
  ];
  if (exact.contains(path)) return true;
  if (prefixes.any(path.startsWith)) return true;
  return userId != null && path.startsWith('/users/$userId/');
}

class _Item {
  const _Item(this.icon, this.label, this.path, {this.match});
  final IconData icon;
  final String label;
  final String path;

  /// Các đường dẫn khác cũng tô đậm mục này
  final List<String>? match;

  bool selected(String location) =>
      location == path ||
      (path != '/account' && location.startsWith('$path/')) ||
      (match?.any(location.startsWith) ?? false);
}

/// Khung trang nhóm Tài khoản trên desktop: menu trái + nội dung bên phải
/// trong khối trắng bo góc, cả hai nằm trong khung 1200px ở giữa.
class AccountDesktopShell extends StatelessWidget {
  const AccountDesktopShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimesions.desktopContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 240, child: _Sidebar(location: location)),
                const SizedBox(width: 24),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final user = context.watchUser();

    final groups = <(String, List<_Item>)>[
      (
        t('Tài khoản của tôi', 'My account'),
        [
          _Item(
            AppIcons.user,
            t('Hồ sơ', 'Profile'),
            '/account',
            match: const ['/profile/edit'],
          ),
          _Item(AppIcons.settings, l.settingsPageTitle, '/settings'),
        ],
      ),
      (
        t('Bán hàng', 'Selling'),
        [
          _Item(
            AppIcons.saveDraft,
            t('Tin nháp', 'Drafts'),
            '/create-listing/drafts',
          ),
          _Item(AppIcons.boost, t('Quảng bá tin', 'Promotions'), '/boost'),
          _Item(AppIcons.stats, t('Thống kê', 'Insights'), '/insights'),
          _Item(AppIcons.store, t('Cửa hàng của tôi', 'My shop'), '/my-shop'),
          _Item(
            AppIcons.posterPromo,
            t('Poster shop', 'Shop posters'),
            '/shop-posters',
          ),
        ],
      ),
      (
        t('Theo dõi', 'Following'),
        [
          _Item(AppIcons.following, l.homeQuickFollowing, '/following'),
          _Item(AppIcons.wantedAlert, l.homeQuickWanted, '/wanted-alerts'),
        ],
      ),
      (
        t('Ví & gói', 'Wallet & plan'),
        [
          _Item(AppIcons.wallet, l.accCoins, '/credits'),
          _Item(AppIcons.pro, l.accProPlan, '/plans'),
        ],
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ảnh, tên người dùng
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/account'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
              child: Row(
                children: [
                  ProfileAvatar(
                    radius: 26,
                    url: user?.avatarUrl,
                    initials: ProfileHeader.initials(user?.fullName ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user == null ? '' : '@${user.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          for (final (title, items) in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            for (final item in items)
              _MenuTile(
                icon: item.icon,
                label: item.label,
                selected: item.selected(location),
                onTap: () => context.go(item.path),
              ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          _MenuTile(
            icon: AppIcons.logout,
            label: l.accLogout,
            danger: true,
            onTap: () async {
              if (await confirmLogout(context) && context.mounted) {
                context.read<AuthBloc>().add(LoggedOut());
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.error
        : selected
        ? AppColors.primaryDark
        : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: danger ? AppColors.error : AppColors.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
