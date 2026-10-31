import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/feedback_view.dart';
import 'admin_assistance.dart';
import 'admin_boost.dart';
import 'admin_catalog.dart';
import 'admin_dashboard.dart';
import 'admin_moderation.dart';
import 'admin_posts.dart';
import 'admin_preview_data.dart';
import 'admin_widgets.dart';

const adminDestinations = <(String, IconData)>[
  ('Tổng quan', Icons.dashboard_outlined),
  ('Kiểm duyệt tin', Icons.fact_check_outlined),
  ('Báo cáo vi phạm', Icons.flag_outlined),
  ('Người dùng', Icons.people_outline),
  ('Danh mục & tình trạng', Icons.category_outlined),
  ('Quản lý Boost', Icons.rocket_launch_outlined),
  ('Bài viết', Icons.article_outlined),
  ('Hỗ trợ người dùng', Icons.support_agent_outlined),
  ('Tri thức AI', Icons.auto_awesome_outlined),
  ('Nhật ký quản trị', Icons.history),
];

class AdminWorkspace extends StatelessWidget {
  const AdminWorkspace({this.onExit, this.initialSection = 0, super.key});
  final VoidCallback? onExit;
  final int initialSection;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AdminPreviewCubit(),
    child: _AdminShell(onExit: onExit, initialSection: initialSection),
  );
}

class _AdminShell extends StatefulWidget {
  const _AdminShell({required this.onExit, required this.initialSection});
  final VoidCallback? onExit;
  final int initialSection;
  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  late int _selected = widget.initialSection;
  String _state = 'Có dữ liệu';
  int _version = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  void _navigate(int index) {
    setState(() {
      _selected = index;
      _state = 'Có dữ liệu';
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1100;
    final title = adminDestinations[_selected].$1;
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
        ),
        chipTheme: Theme.of(context).chipTheme.copyWith(
          selectedColor: AppColors.primarySoft,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: desktop ? null : Drawer(width: 260, child: _sidebar()),
        body: SafeArea(
          child: Row(
            children: [
              if (desktop) SizedBox(width: 232, child: _sidebar()),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      padding: EdgeInsets.symmetric(
                        horizontal: desktop ? 28 : 12,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (!desktop)
                            IconButton(
                              tooltip: 'Mở menu quản trị',
                              onPressed: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                              icon: const Icon(Icons.menu),
                            ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ReStore / Quản trị',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (MediaQuery.sizeOf(context).width >= 600)
                            Text(
                              DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(width: 16),
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primaryDark,
                            child: Text(
                              'LN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      color: AppColors.cream,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 17,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Bản xem trước · Dữ liệu mẫu, thay đổi chỉ lưu trong phiên.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Trạng thái mẫu',
                            icon: const Icon(Icons.tune, size: 18),
                            onSelected: (v) => setState(() => _state = v),
                            itemBuilder: (_) => [
                              for (final label in [
                                'Có dữ liệu',
                                'Đang tải',
                                'Trống',
                                'Lỗi tải',
                                'Không có quyền',
                                'Hết phiên',
                              ])
                                PopupMenuItem(value: label, child: Text(label)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Offstage(
                            offstage: _state != 'Có dữ liệu',
                            child: IndexedStack(
                              key: ValueKey(_version),
                              index: _selected,
                              children: [
                                _scroll(
                                  0,
                                  AdminDashboard(onNavigate: _navigate),
                                ),
                                _scroll(1, const AdminListingsView()),
                                _scroll(2, const AdminReportsView()),
                                _scroll(3, const AdminUsersView()),
                                _scroll(4, const AdminCatalogView()),
                                _scroll(5, const AdminBoostView()),
                                _scroll(6, const AdminPostsView()),
                                _scroll(7, const AdminSupportView()),
                                _scroll(8, const AdminKnowledgeView()),
                                _scroll(
                                  9,
                                  BlocBuilder<
                                    AdminPreviewCubit,
                                    AdminPreviewData
                                  >(
                                    builder: (_, data) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const AdminHeading(
                                          'Nhật ký quản trị',
                                          'Các thay đổi trong phiên xem trước hiện tại.',
                                        ),
                                        AdminHistory(logs: data.logs),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_state != 'Có dữ liệu') _feedback(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scroll(int id, Widget child) => SingleChildScrollView(
    key: PageStorageKey('admin-$_version-$id'),
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
    child: child,
  );

  Widget _sidebar() => Material(
    color: AppColors.surface,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 16, 24),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Flexible(child: Text(
                'ReStore', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              ),
              SizedBox(width: 8),
              Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'ĐIỀU HÀNH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              for (final (i, destination) in adminDestinations.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    key: ValueKey('admin-nav-$i'),
                    dense: true,
                    minLeadingWidth: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: _selected == i,
                    selectedColor: AppColors.primaryDark,
                    selectedTileColor: AppColors.cream,
                    leading: Icon(destination.$2, size: 20),
                    title: Text(
                      destination.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selected == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () => _navigate(i),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linh Nguyễn',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quản trị viên · Tài khoản mẫu',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => adminDialog(
                  context,
                  title: 'Đặt lại phiên xem trước?',
                  width: 460,
                  child: Builder(
                    builder: (c) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mọi thay đổi thử trong phiên sẽ được thay bằng dữ liệu mẫu ban đầu.',
                        ),
                        const SizedBox(height: 20),
                        AdminButton(
                          'Đặt lại',
                          onPressed: () {
                            context.read<AdminPreviewCubit>().reset();
                            setState(() {
                              _version++;
                              _state = 'Có dữ liệu';
                            });
                            Navigator.pop(c);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text(
                  'Đặt lại bản mẫu',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (widget.onExit != null)
                TextButton.icon(
                  onPressed: widget.onExit,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Thoát xem trước',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _feedback() {
    if (_state == 'Đang tải') {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }
    return FeedbackView(
      icon: switch (_state) {
        'Không có quyền' => Icons.lock_outline,
        'Hết phiên' => Icons.timer_off_outlined,
        'Lỗi tải' => Icons.cloud_off_outlined,
        _ => Icons.inbox_outlined,
      },
      title: switch (_state) {
        'Trống' => 'Chưa có dữ liệu',
        'Lỗi tải' => 'Không thể tải dữ liệu',
        'Không có quyền' => 'Bạn không có quyền truy cập',
        _ => 'Phiên làm việc đã hết hạn',
      },
      message: 'Trạng thái minh họa của giao diện quản trị.',
      action: AdminButton(
        'Trở lại bản mẫu',
        onPressed: () => setState(() => _state = 'Có dữ liệu'),
      ),
    );
  }
}
