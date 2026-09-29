import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_dashboard.dart';
import 'admin_preview_data.dart';
import 'admin_widgets.dart';

class AdminBoostView extends StatefulWidget {
  const AdminBoostView({super.key});
  @override
  State<AdminBoostView> createState() => _AdminBoostViewState();
}

class _AdminBoostViewState extends State<AdminBoostView> {
  int _tab = 0;
  String _period = 'Tháng 09/2026', _status = 'Tất cả', _query = '';
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AdminPreviewCubit, AdminPreviewData>(
    builder: (context, data) {
      final payments = adminPayments
          .where((x) => _period != '7 ngày cuối tháng' || x.date.day >= 24)
          .toList();
      final paid = payments.where((x) => x.payment == 'Thành công');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminHeading(
            'Quản lý Boost',
            'Quản lý dịch vụ đẩy tin và theo dõi phí quảng bá.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, label) in [
                'Thống kê',
                'Gói Boost',
                'Giao dịch',
              ].indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: _tab == index,
                  onSelected: (_) => setState(() => _tab = index),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_tab == 0) ...[
            AdminSelect(
              value: _period,
              values: const ['Tháng 09/2026', '7 ngày cuối tháng'],
              label: 'Khoảng thời gian mẫu',
              onChanged: (v) => setState(() => _period = v),
            ),
            const SizedBox(height: 20),
            AdminMetrics(
              items: [
                (
                  'Doanh thu đã xác nhận',
                  adminMoney(paid.fold<int>(0, (s, x) => s + x.amount)),
                  'Thanh toán thành công',
                  Icons.payments_outlined,
                  null,
                ),
                (
                  'Lượt mua',
                  '${payments.length}',
                  'Trong khoảng đã chọn',
                  Icons.shopping_bag_outlined,
                  null,
                ),
                (
                  'Boost đang chạy',
                  '${payments.where((x) => x.boost == 'Đang chạy').length}',
                  'Trong bộ dữ liệu mẫu',
                  Icons.rocket_launch_outlined,
                  null,
                ),
                (
                  'Cần kiểm tra',
                  '${payments.where((x) => x.payment != 'Thành công' || x.boost == 'Lỗi kích hoạt').length}',
                  'Thanh toán / kích hoạt',
                  Icons.info_outline,
                  null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doanh thu theo gói',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  for (final name in ['Khởi đầu', 'Nổi bật', 'Bứt phá'])
                    Builder(
                      builder: (context) {
                        final revenue = paid
                            .where((x) => x.package.startsWith(name))
                            .fold<int>(0, (s, x) => s + x.amount);
                        final total = paid.fold<int>(0, (s, x) => s + x.amount);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(name)),
                                  Text(adminMoney(revenue)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: total == 0 ? 0 : revenue / total,
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.primary,
                                backgroundColor: AppColors.primarySoft,
                                semanticsLabel: '$name: ${adminMoney(revenue)}',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const Text(
                    'Giá và giao dịch minh họa. Doanh thu không bao gồm tiền mua bán sản phẩm.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_tab == 1) ...[
            AdminButton(
              'Thêm gói Boost',
              primary: true,
              icon: Icons.add,
              onPressed: () => _editPackage(context),
            ),
            const SizedBox(height: 20),
            AdminTable(
              columns: const [
                'TÊN GÓI',
                'THỜI LƯỢNG',
                'GIÁ DỊCH VỤ',
                'ƯU TIÊN',
                'TRẠNG THÁI',
                '',
              ],
              rows: [
                for (final x in data.packages)
                  [
                    Text(x.name),
                    Text('${x.days} ngày'),
                    Text(adminMoney(x.price)),
                    Text('${x.priority}'),
                    AdminBadge(x.active ? 'Đang bán' : 'Tạm ngừng'),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _editPackage(context, x),
                          child: const Text('Chỉnh sửa'),
                        ),
                        TextButton(
                          onPressed: () => adminDialog(
                            context,
                            title: x.active ? 'Ngừng bán gói?' : 'Mở bán gói?',
                            width: 480,
                            child: Builder(
                              builder: (dialogContext) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thay đổi áp dụng cho lựa chọn mua mới trong bản mẫu. Thông tin giao dịch cũ được giữ nguyên.',
                                  ),
                                  const SizedBox(height: 20),
                                  AdminButton(
                                    'Xác nhận',
                                    onPressed: () {
                                      context
                                          .read<AdminPreviewCubit>()
                                          .savePackage((
                                            id: x.id,
                                            name: x.name,
                                            days: x.days,
                                            price: x.price,
                                            priority: x.priority,
                                            active: !x.active,
                                          ));
                                      Navigator.pop(dialogContext);
                                      adminNotice(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: Text(x.active ? 'Ngừng bán' : 'Mở bán'),
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ],
          if (_tab == 2) ...[
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                AdminSearch(
                  hint: 'Tìm giao dịch hoặc người mua',
                  onChanged: (v) => setState(() => _query = v),
                ),
                AdminSelect(
                  value: _status,
                  values: const [
                    'Tất cả',
                    'Thành công',
                    'Chờ xác nhận',
                    'Thất bại',
                  ],
                  label: 'Thanh toán',
                  onChanged: (v) => setState(() => _status = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdminTable(
              columns: const [
                'GIAO DỊCH',
                'NGƯỜI MUA',
                'SỐ TIỀN',
                'THANH TOÁN',
                'BOOST',
                '',
              ],
              rows: [
                for (final x in adminPayments.where(
                  (x) =>
                      '${x.id} ${x.user}'.toLowerCase().contains(
                        _query.toLowerCase(),
                      ) &&
                      (_status == 'Tất cả' || x.payment == _status),
                ))
                  [
                    Text('${x.id}\n${DateFormat('dd/MM/yyyy').format(x.date)}'),
                    Text(x.user),
                    Text(adminMoney(x.amount)),
                    AdminBadge(x.payment),
                    AdminBadge(x.boost),
                    TextButton(
                      onPressed: () => adminDialog(
                        context,
                        title: 'Giao dịch ${x.id}',
                        width: 540,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${x.user} · ${x.listing}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Text('Gói đã mua: ${x.package}'),
                            Text('Số tiền: ${adminMoney(x.amount)}'),
                            Text(
                              'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(x.date)}',
                            ),
                            const Divider(height: 32),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                AdminBadge(x.payment),
                                AdminBadge(x.boost),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Cổng thanh toán: VNPAY\nMã tham chiếu thực: chưa kết nối',
                            ),
                            if (x.boost == 'Lỗi kích hoạt')
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text(
                                  'Đã ghi nhận thanh toán nhưng Boost chưa được kích hoạt. Cần đối soát trước khi xử lý.',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                          ],
                        ),
                      ),
                      child: const Text('Chi tiết'),
                    ),
                  ],
              ],
            ),
          ],
        ],
      );
    },
  );

  void _editPackage(BuildContext context, [AdminPackage? item]) {
    final cubit = context.read<AdminPreviewCubit>();
    adminDialog(
      context,
      title: item == null ? 'Thêm gói Boost' : 'Chỉnh sửa gói Boost',
      width: 520,
      child: _PackageForm(item: item, cubit: cubit),
    );
  }
}

class _PackageForm extends StatefulWidget {
  const _PackageForm({required this.item, required this.cubit});
  final AdminPackage? item;
  final AdminPreviewCubit cubit;
  @override
  State<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<_PackageForm> {
  final _key = GlobalKey<FormState>();
  late final _fields = [
    TextEditingController(text: widget.item?.name ?? ''),
    TextEditingController(text: '${widget.item?.days ?? 1}'),
    TextEditingController(text: '${widget.item?.price ?? 19000}'),
    TextEditingController(text: '${widget.item?.priority ?? 1}'),
  ];
  @override
  void dispose() {
    for (final x in _fields) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _key,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, label) in [
          'Tên gói',
          'Thời lượng (ngày)',
          'Giá (VND)',
          'Ưu tiên hiển thị',
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _fields[i],
              keyboardType: i == 0 ? TextInputType.text : TextInputType.number,
              decoration: InputDecoration(labelText: label),
              validator: (v) => i == 0
                  ? (v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập tên gói.'
                        : null)
                  : ((int.tryParse(v ?? '') ?? 0) <= 0
                        ? 'Nhập số nguyên lớn hơn 0.'
                        : null),
            ),
          ),
        AdminButton(
          'Lưu gói mẫu',
          primary: true,
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            widget.cubit.savePackage((
              id:
                  widget.item?.id ??
                  'GOI-${DateTime.now().microsecondsSinceEpoch}',
              name: _fields[0].text.trim(),
              days: int.parse(_fields[1].text),
              price: int.parse(_fields[2].text),
              priority: int.parse(_fields[3].text),
              active: widget.item?.active ?? true,
            ));
            Navigator.pop(context);
            adminNotice(context);
          },
        ),
      ],
    ),
  );
}
