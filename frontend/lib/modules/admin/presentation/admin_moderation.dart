import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_preview_data.dart';
import 'admin_widgets.dart';

String userName(AdminPreviewData data, String id) =>
    data.users.where((x) => x.id == id).firstOrNull?.name ?? id;
String reportTarget(AdminPreviewData data, AdminReport report) => report.isUser
    ? userName(data, report.target)
    : data.listings.where((x) => x.id == report.target).firstOrNull?.title ??
          report.target;

class AdminListingImage extends StatelessWidget {
  const AdminListingImage(this.listing, {this.size = 48, super.key});
  final AdminListing listing;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: Image.asset(
      'assets/images/marketplace/listing-${listing.image}.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      semanticLabel: listing.title,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    ),
  );
}

class AdminListingsView extends StatefulWidget {
  const AdminListingsView({super.key});
  @override
  State<AdminListingsView> createState() => _AdminListingsViewState();
}

class _AdminListingsViewState extends State<AdminListingsView> {
  String _query = '',
      _status = 'Tất cả trạng thái',
      _category = 'Tất cả danh mục';
  int _page = 0;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
        builder: (context, data) {
          final filtered = data.listings
              .where(
                (x) =>
                    ('${x.id} ${x.title} ${userName(data, x.owner)}')
                        .toLowerCase()
                        .contains(_query.toLowerCase()) &&
                    (_status == 'Tất cả trạng thái' || x.status == _status) &&
                    (_category == 'Tất cả danh mục' || x.category == _category),
              )
              .toList();
          final page = _page.clamp(
            0,
            filtered.isEmpty ? 0 : (filtered.length - 1) ~/ 5,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminHeading(
                'Kiểm duyệt tin',
                'Xem xét nội dung để giữ ReStore an toàn và đáng tin cậy.',
              ),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  AdminSearch(
                    hint: 'Tìm mã tin, tiêu đề, người bán',
                    onChanged: (v) => setState(() {
                      _query = v;
                      _page = 0;
                    }),
                  ),
                  AdminSelect(
                    value: _status,
                    values: ['Tất cả trạng thái', ...listingStatuses],
                    label: 'Trạng thái',
                    onChanged: (v) => setState(() {
                      _status = v;
                      _page = 0;
                    }),
                  ),
                  AdminSelect(
                    value: _category,
                    values: const ['Tất cả danh mục', 'Máy ảnh', 'Nội thất'],
                    label: 'Danh mục',
                    onChanged: (v) => setState(() {
                      _category = v;
                      _page = 0;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AdminTable(
                columns: const [
                  'TIN ĐĂNG',
                  'NGƯỜI BÁN',
                  'DANH MỤC',
                  'TRẠNG THÁI',
                  '',
                ],
                rows: [
                  for (final x in filtered.skip(page * 5).take(5))
                    [
                      Row(
                        children: [
                          AdminListingImage(x),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 230,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  x.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${x.id} · ${adminMoney(x.price)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(userName(data, x.owner)),
                      Text(x.category),
                      AdminBadge(x.status),
                      TextButton(
                        onPressed: () => showAdminListing(context, x.id),
                        child: const Text('Xem chi tiết'),
                      ),
                    ],
                ],
              ),
              AdminPager(
                total: filtered.length,
                page: page,
                onChanged: (v) => setState(() => _page = v),
              ),
            ],
          );
        },
      );
}

class AdminPager extends StatelessWidget {
  const AdminPager({
    required this.total,
    required this.page,
    required this.onChanged,
    super.key,
  });
  final int total, page;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            total == 0
                ? '0 kết quả'
                : '${page * 5 + 1}–${((page + 1) * 5).clamp(0, total)} / $total kết quả',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Trang trước',
          onPressed: page > 0 ? () => onChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${page + 1}'),
        IconButton(
          tooltip: 'Trang sau',
          onPressed: (page + 1) * 5 < total ? () => onChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}

void showAdminListing(BuildContext context, String id) {
  final cubit = context.read<AdminPreviewCubit>();
  adminDialog(
    context,
    title: 'Chi tiết kiểm duyệt · $id',
    width: 1000,
    child: BlocProvider.value(
      value: cubit,
      child: BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
        builder: (context, data) {
          final x = data.listings.where((x) => x.id == id).firstOrNull;
          if (x == null) {
            return const AdminEmpty(message: 'Tin đăng không còn tồn tại.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminTwoColumns(
                left: AdminPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: InkWell(
                          onTap: () => adminDialog(
                            context,
                            title: x.title,
                            child: Center(
                              child: AdminListingImage(x, size: 520),
                            ),
                          ),
                          child: AdminListingImage(x, size: 280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        x.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adminMoney(x.price),
                        style: const TextStyle(
                          fontSize: 22,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(height: 32),
                      Text('${x.category} · Đã qua sử dụng · TP. Hồ Chí Minh'),
                      const SizedBox(height: 12),
                      const Text(
                        'Sản phẩm còn sử dụng tốt, có dấu vết sử dụng nhẹ. Người mua có thể liên hệ để xem trực tiếp và trao đổi thêm về tình trạng sản phẩm.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nội dung mô tả mẫu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                right: AdminPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminBadge(x.status),
                      const SizedBox(height: 20),
                      const Text(
                        'NGƯỜI ĐĂNG',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => showAdminUser(context, x.owner),
                        child: Text(userName(data, x.owner)),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Ghi chú kiểm tra',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(x.note),
                      const SizedBox(height: 24),
                      if ([pendingListing, activeListing].contains(x.status))
                        AdminButton(
                          'Ra quyết định',
                          primary: true,
                          icon: Icons.fact_check_outlined,
                          onPressed: () => adminDialog(
                            context,
                            title: 'Quyết định kiểm duyệt',
                            width: 520,
                            child: AdminDecisionForm(
                              actions: x.status == pendingListing
                                  ? const [
                                      activeListing,
                                      'Cần chỉnh sửa',
                                      'Từ chối',
                                    ]
                                  : const ['Đã gỡ'],
                              onSubmit: (action, reason, _) =>
                                  cubit.moderate(id, x.status, action, reason),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AdminHistory(
                logs: data.logs.where((x) => x.target == id).toList(),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});
  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _query = '', _status = 'Tất cả';
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
        builder: (context, data) {
          final users = data.users.where(
            (x) =>
                '${x.id} ${x.name} ${x.email}'.toLowerCase().contains(
                  _query.toLowerCase(),
                ) &&
                (_status == 'Tất cả' || x.status == _status),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminHeading(
                'Người dùng',
                'Theo dõi tài khoản, uy tín và lịch sử xử lý vi phạm.',
              ),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  AdminSearch(
                    hint: 'Tìm tên, email hoặc mã tài khoản',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  AdminSelect(
                    value: _status,
                    values: const ['Tất cả', 'Hoạt động', 'Đình chỉ', 'Đã cấm'],
                    label: 'Trạng thái',
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AdminTable(
                columns: const [
                  'NGƯỜI DÙNG',
                  'VAI TRÒ',
                  'UY TÍN',
                  'NGÀY THAM GIA',
                  'TRẠNG THÁI',
                  '',
                ],
                rows: [
                  for (final x in users)
                    [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primaryDark,
                            child: Text(x.name.characters.first),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                x.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                x.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Text('Thành viên'),
                      Text('★ ${x.rating}'),
                      Text(x.joined),
                      AdminBadge(x.status),
                      TextButton(
                        onPressed: () => showAdminUser(context, x.id),
                        child: const Text('Xem hồ sơ'),
                      ),
                    ],
                ],
              ),
            ],
          );
        },
      );
}

void showAdminUser(BuildContext context, String id) {
  final cubit = context.read<AdminPreviewCubit>();
  adminDialog(
    context,
    title: 'Hồ sơ người dùng · $id',
    child: BlocProvider.value(
      value: cubit,
      child: BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
        builder: (context, data) {
          final user = data.users.where((x) => x.id == id).firstOrNull;
          if (user == null) return const AdminEmpty();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(user.email),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        AdminBadge(user.status),
                        Text('★ ${user.rating} · Tham gia ${user.joined}'),
                        const Text('Email đã xác minh · Dữ liệu mẫu'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AdminButton(
                      'Xử lý tài khoản',
                      danger: true,
                      onPressed: user.status == 'Đã cấm'
                          ? null
                          : () => adminDialog(
                              context,
                              title: 'Xử lý tài khoản',
                              width: 520,
                              child: AdminDecisionForm(
                                actions: [
                                  'Cảnh báo',
                                  if (user.status != 'Đình chỉ') 'Đình chỉ',
                                  'Đã cấm',
                                ],
                                onSubmit: (a, r, d) =>
                                    cubit.sanction(id, a, r, days: d),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AdminPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tin đăng của ${user.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final listing in data.listings.where(
                      (x) => x.owner == id,
                    ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(listing.title),
                        subtitle: Text(listing.status),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showAdminListing(context, listing.id),
                      ),
                    const Divider(),
                    const Text(
                      'Báo cáo liên quan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    for (final report in data.reports.where(
                      (x) =>
                          x.target == id ||
                          x.reporter == id ||
                          data.listings.any(
                            (l) => l.owner == id && l.id == x.target,
                          ),
                    ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${report.id} · ${report.reason}'),
                        subtitle: Text(
                          report.reporter == id
                              ? 'Đã gửi · ${report.status}'
                              : 'Bị báo cáo · ${report.status}',
                        ),
                        onTap: () => showAdminReport(context, report.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AdminHistory(
                logs: data.logs.where((x) => x.target == id).toList(),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});
  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  String _query = '', _type = 'Tất cả', _status = 'Tất cả';
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
    builder: (context, data) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminHeading(
          'Báo cáo vi phạm',
          'Xem bằng chứng, xác minh và ghi nhận kết quả xử lý.',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 16,
          children: [
            AdminSearch(
              hint: 'Tìm mã, đối tượng hoặc lý do',
              onChanged: (v) => setState(() => _query = v),
            ),
            AdminSelect(
              value: _type,
              values: const ['Tất cả', 'Tin đăng', 'Người dùng'],
              label: 'Đối tượng',
              onChanged: (v) => setState(() => _type = v),
            ),
            AdminSelect(
              value: _status,
              values: const [
                'Tất cả',
                'Chưa xử lý',
                'Đã giải quyết',
                'Đã bác bỏ',
              ],
              label: 'Trạng thái',
              onChanged: (v) => setState(() => _status = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AdminTable(
          columns: const ['MÃ BÁO CÁO', 'ĐỐI TƯỢNG', 'LÝ DO', 'TRẠNG THÁI', ''],
          rows: [
            for (final x in data.reports.where(
              (x) =>
                  ('${x.id} ${reportTarget(data, x)} ${x.reason}')
                      .toLowerCase()
                      .contains(_query.toLowerCase()) &&
                  (_type == 'Tất cả' || x.isUser == (_type == 'Người dùng')) &&
                  (_status == 'Tất cả' || x.status == _status),
            ))
              [
                Text(x.id),
                SizedBox(
                  width: 230,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportTarget(data, x),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        x.isUser ? 'Người dùng' : 'Tin đăng',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(x.reason),
                AdminBadge(x.status),
                TextButton(
                  onPressed: () => showAdminReport(context, x.id),
                  child: const Text('Xem báo cáo'),
                ),
              ],
          ],
        ),
      ],
    ),
  );
}

void showAdminReport(BuildContext context, String id) {
  final cubit = context.read<AdminPreviewCubit>();
  adminDialog(
    context,
    title: 'Chi tiết báo cáo · $id',
    child: BlocProvider.value(
      value: cubit,
      child: BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
        builder: (context, data) {
          final report = data.reports.where((x) => x.id == id).firstOrNull;
          if (report == null) return const AdminEmpty();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminBadge(report.status),
                    const SizedBox(height: 16),
                    Text(
                      report.reason,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text('Người gửi: ${userName(data, report.reporter)}'),
                    TextButton(
                      onPressed: () => report.isUser
                          ? showAdminUser(context, report.target)
                          : showAdminListing(context, report.target),
                      child: Text('Đối tượng: ${reportTarget(data, report)}'),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Nội dung / bằng chứng',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(report.evidence),
                    const SizedBox(height: 20),
                    if (report.status == 'Chưa xử lý')
                      AdminButton(
                        'Xử lý báo cáo',
                        primary: true,
                        onPressed: () => adminDialog(
                          context,
                          title: 'Kết luận báo cáo',
                          width: 540,
                          child: AdminDecisionForm(
                            actions: report.isUser
                                ? const [
                                    'Cảnh báo',
                                    'Đình chỉ',
                                    'Đã cấm',
                                    'Bác báo cáo',
                                  ]
                                : [
                                    if (data.listings.any(
                                      (x) =>
                                          x.id == report.target &&
                                          x.status == activeListing,
                                    ))
                                      'Gỡ tin',
                                    'Giữ tin',
                                    'Bác báo cáo',
                                  ],
                            onSubmit: (a, r, d) =>
                                cubit.resolve(id, a, r, days: d),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AdminHistory(
                logs: data.logs.where((x) => x.target == id).toList(),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class AdminHistory extends StatelessWidget {
  const AdminHistory({required this.logs, super.key});
  final List<AdminLog> logs;
  @override
  Widget build(BuildContext context) => AdminPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử quản trị',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Chưa có thao tác trong phiên xem trước.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        for (final log in logs)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: AppColors.primaryDark),
            title: Text('${log.action} · ${log.target}'),
            subtitle: Text(
              '${log.reason.isEmpty ? 'Đã xem xét nội dung' : log.reason}\nLinh Nguyễn · ${DateFormat('dd/MM HH:mm').format(log.time)}',
            ),
          ),
      ],
    ),
  );
}
