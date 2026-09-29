import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/listing_grid.dart';
import '../../listings/presentation/fixtures/figma_preview_listings.dart';
import '../bloc/account_ui_cubit.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<EditProfileCubit, EditProfileState>(
      listenWhen: (previous, current) => !previous.saved && current.saved,
      listener: (context, state) => context.pop(),
      child: _DetailScaffold(
        title: l10n.editProfileTitle,
        footer: _PrimaryFooter(
          label: l10n.saveChanges,
          onPressed: context.read<EditProfileCubit>().submitted,
        ),
        child: BlocBuilder<EditProfileCubit, EditProfileState>(
          builder: (context, state) => Column(
            children: [
              const SizedBox(height: 4),
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
              TextButton(onPressed: () {}, child: Text(l10n.changeAvatar)),
              _ProfileField(
                label: l10n.fullName,
                initialValue: state.name,
                onChanged: context.read<EditProfileCubit>().nameChanged,
              ),
              _ProfileField(
                label: l10n.phoneNumber,
                initialValue: state.phone,
                keyboardType: TextInputType.phone,
                onChanged: context.read<EditProfileCubit>().phoneChanged,
              ),
              _ProfileField(
                label: l10n.birthday,
                initialValue: state.birthday,
                onChanged: context.read<EditProfileCubit>().birthdayChanged,
              ),
              _SelectField(
                label: l10n.gender,
                value: state.gender,
                values: {
                  'male': l10n.male,
                  'female': l10n.female,
                  'other': l10n.other,
                },
                onChanged: context.read<EditProfileCubit>().genderChanged,
              ),
              _SelectField(
                label: l10n.area,
                value: state.area,
                values: {
                  'district1': l10n.district1Hcm,
                  'thuDuc': l10n.thuDucHcm,
                  'district3': l10n.district3Hcm,
                },
                onChanged: context.read<EditProfileCubit>().areaChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DetailScaffold(
      title: l10n.settingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.options,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<SettingsCubit, bool>(
            builder: (context, enabled) => _SettingsItem(
              icon: Icons.notifications_none,
              label: l10n.receiveNotifications,
              trailing: Switch(
                value: enabled,
                activeTrackColor: AppColors.primary,
                onChanged: context.read<SettingsCubit>().notificationsChanged,
              ),
            ),
          ),
          _SettingsItem(
            icon: Icons.shield_outlined,
            label: l10n.privacy,
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.lock_outline,
            label: l10n.changePassword,
            onTap: () => context.push('/forgot-password'),
          ),
          _SettingsItem(
            icon: Icons.help_outline,
            label: l10n.helpSupport,
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.description_outlined,
            label: l10n.termsPolicies,
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.logout,
            label: l10n.logout,
            onTap: () => context.go('/welcome'),
          ),
        ],
      ),
    );
  }
}

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saved = figmaPreviewListings.take(4).toList();
    return _DetailScaffold(
      title: l10n.savedListings,
      child: saved.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 54,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.emptySavedTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.emptySavedDescription),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: Text(l10n.exploreProducts),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    Text(
                      l10n.savedCount(saved.length),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.tapHeartToRemove,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListingGrid(listings: saved),
              ],
            ),
    );
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = <String, List<_NotificationData>>{
      l10n.today: [
        _NotificationData(
          Icons.chat_bubble_outline,
          l10n.newMessage,
          l10n.newMessageDescription,
          '09:44',
          true,
        ),
        _NotificationData(
          Icons.sell_outlined,
          l10n.newOffer,
          l10n.newOfferDescription,
          '09:47',
          true,
        ),
        _NotificationData(
          Icons.swap_horiz,
          l10n.offerResponse,
          l10n.offerResponseDescription,
          '09:52',
          false,
        ),
      ],
      l10n.yesterday: [
        _NotificationData(
          Icons.verified_outlined,
          l10n.listingApproved,
          l10n.listingApprovedDescription,
          '18:30',
          false,
        ),
        _NotificationData(
          Icons.edit_note,
          l10n.listingNeedsEdit,
          l10n.listingNeedsEditDescription,
          '15:10',
          false,
        ),
      ],
      l10n.earlier: [
        _NotificationData(
          Icons.favorite_border,
          l10n.listingSavedNotification,
          l10n.listingSavedDescription,
          '12/09',
          false,
        ),
      ],
    };
    return _DetailScaffold(
      title: l10n.notifications,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.expand((group) sync* {
          yield Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Text(
              group.key,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          );
          for (final item in group.value) {
            yield _NotificationCard(item: item);
          }
        }).toList(),
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(maxWidth: 720, child: child),
    ),
    bottomNavigationBar: footer,
  );
}

class _PrimaryFooter extends StatelessWidget {
  const _PrimaryFooter({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(onPressed: onPressed, child: Text(label)),
        ),
      ),
    ),
  );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: values.entries
              .map(
                (item) =>
                    DropdownMenuItem(value: item.key, child: Text(item.value)),
              )
              .toList(),
          onChanged: (item) {
            if (item != null) onChanged(item);
          },
        ),
      ],
    ),
  );
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        height: 55,
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
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    ),
  );
}

class _NotificationData {
  const _NotificationData(
    this.icon,
    this.title,
    this.description,
    this.time,
    this.unread,
  );

  final IconData icon;
  final String title;
  final String description;
  final String time;
  final bool unread;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final _NotificationData item;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 83),
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: item.unread ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.surface,
          child: Icon(item.icon, size: 20, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.unread) ...[
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 3,
                      backgroundColor: AppColors.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
