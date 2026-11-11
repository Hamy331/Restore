import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/boost/views/promotion_hub/promotion_hub_view.dart';
import 'package:restore/modules/insights/views/insights/insights_view.dart';
import 'package:restore/modules/shop_posters/views/shop_posters/shop_posters_view.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import '../bloc/shell_badges_cubit.dart';
import '../models/shell_quick_action.dart';
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

  /// Nút trong menu xoè của gói tier cao. Đăng tin mở trang đăng, Đẩy tin
  /// mở trang Boost (danh sách tin để quảng bá), Thống kê mở trang Thống kê,
  /// Shop poster mở trang quản lý poster; trang shop báo sắp có.
  void _quickAction(BuildContext context, ShellQuickAction action) {
    if (action == ShellQuickAction.post) {
      _select(context, 2);
      return;
    }
    if (action == ShellQuickAction.boost) {
      context.push(PromotionHubView.path);
      return;
    }
    if (action == ShellQuickAction.stats) {
      context.push(InsightsView.path);
      return;
    }
    if (action == ShellQuickAction.poster) {
      context.push(ShopPostersView.path);
      return;
    }
    TSnackBarHelper.showInfo(
      context,
      message: AppLocalizations.of(context)!.featureComingSoon,
    );
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
      // Gói lấy từ nút test đổi gói (chưa có API gói đăng ký)
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: DevPlanOverride.plan,
        builder: (context, plan, _) => BlocBuilder<ShellBadgesCubit, int>(
          builder: (context, unread) => ShellBottomNav(
            selectedIndex: _uiIndex,
            onSelected: (i) => _select(context, i),
            unreadMessages: unread,
            quickActions: ShellQuickAction.forPlan(plan),
            onQuickAction: (action) => _quickAction(context, action),
          ),
        ),
      ),
    );
  }
}
