import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../../../core/constants/app_colors.dart';

class ShellNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ShellNavRail({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationRail(
      backgroundColor: AppColors.surface,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            tooltip: l10n.createListing,
            onPressed: () => onSelected(2),
            icon: const Icon(AppIcons.add),
          ),
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(AppIcons.home),
          selectedIcon: const Icon(AppIcons.homeActive),
          label: Text(l10n.homeTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(AppIcons.feeds),
          selectedIcon: const Icon(AppIcons.feedsActive),
          label: Text(l10n.feedsTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(AppIcons.post),
          selectedIcon: const Icon(AppIcons.postActive),
          label: Text(l10n.createListing),
        ),
        NavigationRailDestination(
          icon: const Icon(AppIcons.chat),
          selectedIcon: const Icon(AppIcons.chatActive),
          label: Text(l10n.messagesTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(AppIcons.user),
          selectedIcon: const Icon(AppIcons.userActive),
          label: Text(l10n.accountTitle),
        ),
      ],
    );
  }
}
