import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/shell_bottom_nav.dart';
import '../widgets/shell_nav_rail.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  // Tính lại Index cho UI (có 5 nút) dựa trên 4 Tab của Router
  int get _uiIndex {
    if (navigationShell.currentIndex >= 2) {
      return navigationShell.currentIndex + 1;
    }
    return navigationShell.currentIndex;
  }

  void _select(BuildContext context, int index) {
    // Nếu bấm nút (+) Đăng tin -> Push hẳn trang mới, giữ nguyên Tab hiện tại ở nền
    if (index == 2) {
      context.push('/create-listing/choose-category');
      return;
    }

    // Nếu bấm các nút khác -> Chuyển Branch tương ứng
    int branchIndex = index > 2 ? index - 1 : index;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              ShellNavRail(
                selectedIndex: _uiIndex,
                onSelected: (i) => _select(context, i),
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
      bottomNavigationBar: ShellBottomNav(
        selectedIndex: _uiIndex,
        onSelected: (i) => _select(context, i),
      ),
    );
  }
}
