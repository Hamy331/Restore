import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
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
                      tooltip: 'Đăng tin',
                      onPressed: () => _select(2),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Trang chủ'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: Text('Quản lý tin'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.add_box_outlined),
                    selectedIcon: Icon(Icons.add_box),
                    label: Text('Đăng tin'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: Text('Tin nhắn'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Tài khoản'),
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

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home, 'Trang chủ'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Quản lý tin'),
    (Icons.add, Icons.add, 'Đăng tin'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Tin nhắn'),
    (Icons.person_outline, Icons.person, 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
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
          children: List.generate(_items.length, (index) {
            final item = _items[index];
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
