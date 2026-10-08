import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
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
            icon: const Icon(Icons.add),
          ),
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text(l10n.homeTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: Text(l10n.manageListings),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.add_box_outlined),
          selectedIcon: const Icon(Icons.add_box),
          label: Text(l10n.createListing),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.chat_bubble_outline),
          selectedIcon: const Icon(Icons.chat_bubble),
          label: Text(l10n.messagesTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: Text(l10n.accountTitle),
        ),
      ],
    );
  }
}
