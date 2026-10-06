import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    return SafeArea(
      child: Column(
        children: [
          ResponsiveContent(
            maxWidth: 720,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Text(
                    l10n.accountTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.settingsTitle,
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ResponsiveContent(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IdentityCard(
                        onEdit: () => context.push('/account/edit'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              value: 3.toString(),
                              label: l10n.activeListings,
                              onTap: () => context.go('/manage-listings'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              value: 12.toString(),
                              label: l10n.soldListings,
                              onTap: () => context.go('/manage-listings'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.myAccount,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _AccountItem(
                        icon: Icons.favorite_border,
                        label: l10n.savedListings,
                        trailing: 4.toString(),
                        onTap: () => context.push('/favorites'),
                      ),
                      _AccountItem(
                        icon: Icons.star_border,
                        label: l10n.reviews,
                        trailing: 48.toString(),
                        onTap: () => context.push('/seller/minh-anh/reviews'),
                      ),
                      _AccountItem(
                        icon: Icons.notifications_none,
                        label: l10n.notifications,
                        trailing: l10n.newCount(2),
                        onTap: () => context.push('/notifications'),
                      ),
                      _AccountItem(
                        icon: Icons.location_on_outlined,
                        label: l10n.addressArea,
                        onTap: () => context.push('/account/edit'),
                      ),
                      if (!isAdmin) _AccountItem(
                        icon: Icons.storefront_outlined,
                        label: 'Gói cửa hàng Basic / Pro',
                        onTap: () => context.push('/store'),
                      ),
                      if (!isAdmin) _AccountItem(
                        icon: Icons.campaign_outlined,
                        label: 'Đẩy Tin và Tin Ưu Tiên',
                        onTap: () => context.push('/promotions'),
                      ),
                      if (isAdmin)
                        _AccountItem(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Xác nhận đơn cửa hàng và quảng cáo',
                          onTap: () => context.push('/admin/commerce'),
                        ),
                      _AccountItem(
                        icon: Icons.auto_awesome_outlined,
                        label: l10n.restoreAi,
                        onTap: () => context.push('/ai-assistant'),
                      ),
                      _AccountItem(
                        icon: Icons.settings_outlined,
                        label: l10n.settingsTitle,
                        onTap: () => context.push('/settings'),
                      ),
                      _AccountItem(
                        icon: Icons.help_outline,
                        label: l10n.help,
                        onTap: () => context.push('/settings'),
                      ),
                      _AccountItem(
                        icon: Icons.logout,
                        label: l10n.logout,
                        onTap: () => context.read<AuthBloc>().add(LoggedOut()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.infoBg,
            child: Text(
              'TP',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.memberSince2022,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.maskedPhoneArea,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${l10n.editProfile}  ›',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: Ink(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.1),
          ),
        ],
      ),
    ),
  );
}

class _AccountItem extends StatelessWidget {
  const _AccountItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryDark,
                ),
              ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
