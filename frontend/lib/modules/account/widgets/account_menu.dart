import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../trusted_shop/views/trusted_shops/trusted_shops_view.dart';
import 'profile_header.dart';

/// Báo tính năng chưa có màn hình; giữ nút theo thiết kế Figma.
void showComingSoon(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.accComingSoon)),
    );

/// Ngăn kéo menu bên phải của tab Tài khoản.
void showAccountMenu(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  showGeneralDialog<void>(
    context: context,
    barrierLabel: l.accCloseMenu,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) {
      void open(String path) {
        Navigator.of(dialogContext).pop();
        context.push(path);
      }

      void soon() => showComingSoon(dialogContext);

      final width = MediaQuery.sizeOf(context).width * .75;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: AppColors.background,
          child: SizedBox(
            width: width > 360 ? 360 : width,
            height: double.infinity,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 28, 14, 28),
                child: Column(
                  children: [
                    _MenuGroup(
                      items: [
                        _MenuItem(AppIcons.wallet, l.accCoins, onTap: soon),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(AppIcons.favorite, l.accSaved, onTap: soon),
                        _MenuItem(
                          AppIcons.search,
                          l.accSavedSearches,
                          onTap: soon,
                        ),
                        _MenuItem(
                          AppIcons.clock,
                          l.accRecentlyViewed,
                          onTap: soon,
                        ),
                        _MenuItem(AppIcons.star, l.accMyReviews, onTap: soon),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(AppIcons.pro, l.accProPlan, onTap: soon),
                        _MenuItem(
                          AppIcons.listings,
                          l.accTransactions,
                          onTap: soon,
                        ),
                        _MenuItem(
                          AppIcons.store,
                          l.accStores,
                          onTap: () => open(TrustedShopsView.path),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          AppIcons.settings,
                          l.settingsPageTitle,
                          onTap: () => open('/settings'),
                        ),
                        _MenuItem(AppIcons.help, l.accHelp, onTap: soon),
                        _MenuItem(AppIcons.chat, l.accFeedback, onTap: soon),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          AppIcons.logout,
                          l.accLogout,
                          danger: true,
                          onTap: () async {
                            Navigator.of(dialogContext).pop();
                            if (await _confirmLogout(context) &&
                                context.mounted) {
                              context.read<AuthBloc>().add(LoggedOut());
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

Future<bool> _confirmLogout(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  return await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          content: Text(l.accLogoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l.accLogout),
            ),
          ],
        ),
      ) ==
      true;
}

class _MenuItem {
  const _MenuItem(
    this.icon,
    this.label, {
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            InkWell(
              onTap: items[i].onTap,
              child: SizedBox(
                height: 57,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Row(
                    children: [
                      Icon(
                        items[i].icon,
                        size: 22,
                        color: items[i].danger
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Text(
                          items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: profileFontFamily,
                            fontSize: 14,
                            color: items[i].danger
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        AppIcons.chevronRight,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
