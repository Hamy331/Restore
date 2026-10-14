import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import '../bloc/shell_badges_cubit.dart';
import '../widgets/shell_ai_bubble.dart';
import '../widgets/shell_bottom_nav.dart';
import '../widgets/shell_nav_rail.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const String _aiAssistantPath = '/ai-assistant';

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
      context.push(CreateListingStep.category.path);
      return;
    }

    // Nếu bấm các nút khác -> Chuyển Branch tương ứng
    int branchIndex = index > 2 ? index - 1 : index;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
    // Cập nhật lại số tin chưa đọc mỗi lần đổi tab
    context.read<ShellBadgesCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    final aiBubble = ShellAiBubble(onTap: () => context.push(_aiAssistantPath));

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
              Expanded(
                child: Stack(
                  children: [
                    navigationShell,
                    Positioned.fill(child: aiBubble),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // extendBody: nội dung chạy xuống dưới thanh điều hướng kính để thấy
    // hiệu ứng mờ; MediaQuery padding dưới của body đã gồm chiều cao thanh
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          Positioned.fill(child: aiBubble),
        ],
      ),
      bottomNavigationBar: BlocBuilder<ShellBadgesCubit, int>(
        builder: (context, unread) => ShellBottomNav(
          selectedIndex: _uiIndex,
          onSelected: (i) => _select(context, i),
          unreadMessages: unread,
        ),
      ),
    );
  }
}
