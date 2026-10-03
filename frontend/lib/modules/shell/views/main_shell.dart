import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                backgroundColor: AppColors.surface,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _select,
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
                      onPressed: () => _select(2),
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
              ),
              const VerticalDivider(width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _MarketplaceBottomNavigation(
        selectedIndex: navigationShell.currentIndex,
        onSelected: _select,
      ),
    );
  }
}

class _MarketplaceBottomNavigation extends StatelessWidget {
  const _MarketplaceBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home, l10n.homeTitle),
      (Icons.inventory_2_outlined, Icons.inventory_2, l10n.manageListings),
      (Icons.add, Icons.add, l10n.createListing),
      (Icons.chat_bubble_outline, Icons.chat_bubble, l10n.messagesTitle),
      (Icons.person_outline, Icons.person, l10n.accountTitle),
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == selectedIndex;
            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: item.$3,
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 2)
                        Container(
                          width: 44,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, size: 27),
                        )
                      else
                        Icon(
                          selected ? item.$2 : item.$1,
                          size: 23,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
