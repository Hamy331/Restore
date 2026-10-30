import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_preview_data.dart';
import 'admin_widgets.dart';
import 'admin_moderation.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({required this.onNavigate, super.key});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
    builder: (context, data) {
      final pending = data.listings
          .where((x) => x.status == pendingListing)
          .toList();
      final reports = data.reports
          .where((x) => x.status == 'Chưa xử lý')
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminHeading(
            'Tổng quan',
            'Chào Linh, đây là những việc cần bạn xem xét.',
          ),
          AdminMetrics(
            items: [
              (
                'Tin chờ duyệt',
                '${pending.length}',
                'Mở hàng đợi kiểm duyệt',
                Icons.fact_check_outlined,
                () => onNavigate(1),
              ),
              (
                'Báo cáo chưa xử lý',
                '${reports.length}',
                'Xem các phản ánh mới',
                Icons.flag_outlined,
                () => onNavigate(2),
              ),
              (
                'Người dùng hoạt động',
                '${data.users.where((x) => x.status == 'Hoạt động').length}',
                'Trong bộ dữ liệu mẫu',
                Icons.people_outline,
                () => onNavigate(3),
              ),
              (
                'Tin đang hiển thị',
                '${data.listings.where((x) => x.status == activeListing).length}',
                'Đã được phê duyệt',
                Icons.inventory_2_outlined,
                () => onNavigate(1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AdminTwoColumns(
            equal: true,
            left: AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelTitle(
                    'Tin cần xem xét gần đây',
                    'Xem hàng đợi',
                    () => onNavigate(1),
                  ),
                  if (pending.isEmpty)
                    const AdminEmpty(
                      message: 'Bạn đã xử lý hết tin chờ duyệt trong bản mẫu.',
                    ),
                  for (final x in pending.take(3))
                    Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: AdminListingImage(x),
                          title: Text(
                            x.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${userName(data, x.owner)} · ${x.note}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () => showAdminListing(context, x.id),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                ],
              ),
            ),
            right: AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelTitle(
                    'Báo cáo mới',
                    'Xem báo cáo',
                    () => onNavigate(2),
                  ),
                  if (reports.isEmpty)
                    const AdminEmpty(
                      message: 'Không còn báo cáo chưa xử lý trong bản mẫu.',
                    ),
                  for (final x in reports.take(3))
                    Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: const Icon(
                            Icons.flag_outlined,
                            color: AppColors.primaryDark,
                          ),
                          title: Text(
                            reportTarget(data, x),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            x.reason,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () => showAdminReport(context, x.id),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AdminHistory(logs: data.logs.take(5).toList()),
          const SizedBox(height: 24),
          AdminPanel(
            child: Row(
              children: [
                const Icon(
                  Icons.rocket_launch_outlined,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Doanh thu Boost mẫu: ${adminMoney(adminPayments.where((x) => x.payment == 'Thành công').fold<int>(0, (sum, x) => sum + x.amount))}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(5),
                  child: const Text('Chi tiết'),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.title, this.action, this.onTap);
  final String title, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

typedef AdminMetric = (String, String, String, IconData, VoidCallback?);

class AdminMetrics extends StatelessWidget {
  const AdminMetrics({required this.items, super.key});
  final List<AdminMetric> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 1000
          ? 4
          : c.maxWidth >= 480
          ? 2
          : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final item in items)
            SizedBox(
              width: (c.maxWidth - (columns - 1) * 16) / columns,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: item.$5,
                  child: AdminPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.$1,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Icon(
                              item.$4,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
