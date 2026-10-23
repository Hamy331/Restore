import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  late Future<Map<String, dynamic>> _counts = _loadCounts();
  Future<void> _openListings() async {
    await context.push('/manage-listings');
    if (mounted) setState(() => _counts = _loadCounts());
  }

  Future<Map<String, dynamic>> _loadCounts() async {
    if (AppEnvironment.useMockData) return {'active': 3, 'sold': 12};
    final response = await ApiClient().dio.get<Map<String, dynamic>>(
      '/listings/summary',
    );
    return Map<String, dynamic>.from(response.data?['data'] as Map);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
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
                    icon: const Icon(AppIcons.settings),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SingleChildScrollView(
                // Chừa chỗ cho thanh điều hướng kính nổi phía dưới
                padding: EdgeInsets.only(
                  top: 12,
                  bottom: 12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: ResponsiveContent(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IdentityCard(
                        onEdit: () => context.push('/account/edit'),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _counts,
                        builder: (context, snapshot) => Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                value: '${snapshot.data?['active'] ?? '—'}',
                                label: l10n.activeListings,
                                onTap: _openListings,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                value: '${snapshot.data?['sold'] ?? '—'}',
                                label: l10n.soldListings,
                                onTap: _openListings,
                              ),
                            ),
                          ],
                        ),
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
                        icon: AppIcons.favorite,
                        label: l10n.savedListings,
                        onTap: () => context.push('/favorites'),
                      ),
                      _AccountItem(
                        icon: AppIcons.star,
                        label: l10n.reviews,
                        trailing: 48.toString(),
                        onTap: () => context.push('/seller/minh-anh/reviews'),
                      ),
                      _AccountItem(
                        icon: AppIcons.notification,
                        label: l10n.notifications,
                        trailing: l10n.newCount(2),
                        onTap: () => context.push('/notifications'),
                      ),
                      _AccountItem(
                        icon: AppIcons.location,
                        label: l10n.addressArea,
                        onTap: () => context.push('/account/edit'),
                      ),
                      _AccountItem(
                        icon: AppIcons.sparkle,
                        label: l10n.restoreAi,
                        onTap: () => context.push('/ai-assistant'),
                      ),
                      _AccountItem(
                        icon: AppIcons.settings,
                        label: l10n.settingsTitle,
                        onTap: () => context.push('/settings'),
                      ),
                      _AccountItem(
                        icon: AppIcons.help,
                        label: l10n.help,
                        onTap: () => context.push('/settings'),
                      ),
                      _AccountItem(
                        icon: AppIcons.logout,
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
              AppIcons.chevronRight,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}
