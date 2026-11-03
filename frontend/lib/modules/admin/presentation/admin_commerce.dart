import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../stores/data/store_repository.dart';

class AdminOrderHistory extends StatefulWidget {
  const AdminOrderHistory({required this.repository, super.key});
  final StoreRepository repository;
  @override
  State<AdminOrderHistory> createState() => _AdminOrderHistoryState();
}

class _AdminOrderHistoryState extends State<AdminOrderHistory> {
  String _type = 'stores', _status = '';
  int _page = 1;
  late Future<Map<String, dynamic>> _data = _load();
  Future<Map<String, dynamic>> _load() =>
      widget.repository.orderHistory(_type, _page, _status);
  void _refresh() => setState(() => _data = _load());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch sử đơn mua')),
    body: Column(
      children: [
        Wrap(
          spacing: 12,
          children: [
            DropdownButton<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'stores', child: Text('Cửa hàng')),
                DropdownMenuItem(value: 'promotions', child: Text('Quảng cáo')),
              ],
              onChanged: (value) {
                _type = value!;
                _page = 1;
                _refresh();
              },
            ),
            DropdownButton<String>(
              value: _status,
              items: [
                for (final value in ['', 'PENDING', 'CONFIRMED', 'REJECTED'])
                  DropdownMenuItem(
                    value: value,
                    child: Text(value.isEmpty ? 'Tất cả' : value),
                  ),
              ],
              onChanged: (value) {
                _status = value!;
                _page = 1;
                _refresh();
              },
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: _refresh,
                    child: const Text('Không tải được lịch sử. Thử lại'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!, rows = data['items'] as List;
              return ListView(
                children: [
                  for (final row in rows)
                    ListTile(
                      title: Text(
                        '${row['package']['name']} · ${row['amount']} đ',
                      ),
                      subtitle: Text(
                        '${row['user']['fullName']} · ${row['status']}\n${row['id']} · ${row['createdAt']}\nXử lý: ${row['decidedAt'] ?? 'Chưa xử lý'}',
                      ),
                    ),
                  if (rows.isEmpty)
                    const ListTile(title: Text('Không có đơn trong mục này.')),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _page > 1
                            ? () {
                                _page--;
                                _refresh();
                              }
                            : null,
                        child: const Text('Trang trước'),
                      ),
                      Text('$_page'),
                      TextButton(
                        onPressed: _page * 25 < (data['total'] as int)
                            ? () {
                                _page++;
                                _refresh();
                              }
                            : null,
                        child: const Text('Trang sau'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class AdminCommerceView extends StatefulWidget {
  const AdminCommerceView({this.repository, super.key});
  final StoreRepository? repository;
  @override
  State<AdminCommerceView> createState() => _AdminCommerceViewState();
}

class _AdminCommerceViewState extends State<AdminCommerceView> {
  late final StoreRepository _repository =
      widget.repository ?? StoreRepository();
  late Future<
    (
      List<Map<String, dynamic>>,
      List<Map<String, dynamic>>,
      List<PromotionPackage>,
      List<StorePackage>,
    )
  >
  _orders = _load();
  String? _busyId;

  Future<
    (
      List<Map<String, dynamic>>,
      List<Map<String, dynamic>>,
      List<PromotionPackage>,
      List<StorePackage>,
    )
  >
  _load() async => (
    await _repository.pendingOrders('stores'),
    await _repository.pendingOrders('promotions'),
    await _repository.allPromotionPackages(),
    await _repository.adminStorePackages(),
  );

  Future<void> _editStorePackage(StorePackage item) async {
    final fields = <String, String>{
      'name': item.name,
      'monthlyPrice': item.monthlyPrice,
      'dailyListingLimit': '${item.dailyListingLimit}',
      'activeListingLimit': '${item.activeListingLimit}',
      'monthlyPromotionQuota': '${item.monthlyPromotionQuota}',
      'priorityLevel': '${item.priorityLevel}',
    };
    final controllers = fields.map(
      (key, value) => MapEntry(key, TextEditingController(text: value)),
    );
    var saving = false;
    String error = '';
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text('Cấu hình ${item.name}'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Thay đổi hạn mức áp dụng cho cả thuê bao hiện có. Giá mới áp dụng đơn mua mới.',
                    ),
                    for (final entry in controllers.entries)
                      TextField(
                        controller: entry.value,
                        enabled: !saving,
                        decoration: InputDecoration(
                          labelText: const {
                            'name': 'Tên gói',
                            'monthlyPrice': 'Giá / 30 ngày',
                            'dailyListingLimit': 'Tin / ngày',
                            'activeListingLimit': 'Tin hoạt động',
                            'monthlyPromotionQuota': 'Lượt quảng cáo / tháng',
                            'priorityLevel': 'Mức ưu tiên',
                          }[entry.key],
                        ),
                        keyboardType: entry.key == 'name'
                            ? TextInputType.text
                            : TextInputType.number,
                      ),
                    if (error.isNotEmpty)
                      Text(
                        error,
                        style: const TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialog),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        update(() => saving = true);
                        try {
                          await _repository.saveStorePackage(item.id, {
                            for (final entry in controllers.entries)
                              entry.key:
                                  ['name', 'monthlyPrice'].contains(entry.key)
                                  ? entry.value.text
                                  : int.parse(entry.value.text),
                          });
                          if (dialog.mounted) Navigator.pop(dialog);
                          if (mounted) setState(() => _orders = _load());
                        } catch (_) {
                          if (dialog.mounted) {
                            update(
                              () => error =
                                  'Dữ liệu không hợp lệ hoặc không lưu được gói.',
                            );
                          }
                        } finally {
                          if (dialog.mounted) update(() => saving = false);
                        }
                      },
                child: const Text('Lưu cấu hình'),
              ),
            ],
          ),
        ),
      );
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  Future<void> _editPackage([PromotionPackage? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final price = TextEditingController(text: item?.price ?? '');
    var kind = item?.kind ?? 'BUMP';
    var duration = item?.durationDays ?? 1;
    var active = item?.active ?? true;
    var saving = false;
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text(
              item == null ? 'Thêm gói quảng cáo' : 'Sửa gói quảng cáo',
            ),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Tên gói'),
                        validator: (value) => (value?.trim().length ?? 0) < 3
                            ? 'Tên cần ít nhất 3 ký tự'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: kind,
                        decoration: const InputDecoration(labelText: 'Loại'),
                        items: const [
                          DropdownMenuItem(
                            value: 'BUMP',
                            child: Text('Đẩy Tin'),
                          ),
                          DropdownMenuItem(
                            value: 'FEATURED',
                            child: Text('Tin Ưu Tiên'),
                          ),
                        ],
                        onChanged: (value) => update(() => kind = value!),
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: duration,
                        decoration: const InputDecoration(
                          labelText: 'Thời hạn',
                        ),
                        items: List.generate(30, (index) => index + 1)
                            .map(
                              (days) => DropdownMenuItem(
                                value: days,
                                child: Text('$days ngày'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => update(() => duration = value!),
                      ),
                      TextFormField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá (VND)',
                        ),
                        validator: (value) =>
                            RegExp(r'^[1-9]\d{0,11}$').hasMatch(value ?? '')
                            ? null
                            : 'Nhập giá VND hợp lệ',
                      ),
                      SwitchListTile(
                        title: const Text('Đang bán'),
                        value: active,
                        onChanged: (value) => update(() => active = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        update(() => saving = true);
                        try {
                          await _repository.savePromotionPackage(
                            id: item?.id,
                            name: name.text.trim(),
                            kind: kind,
                            durationDays: duration,
                            price: price.text,
                            priority: kind == item?.kind
                                ? item!.priority
                                : (kind == 'BUMP' ? 0 : 3),
                            active: active,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (mounted) setState(() => _orders = _load());
                        } catch (_) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không lưu được gói. Gói đã có giao dịch chỉ được sửa tên, giá và trạng thái.',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            update(() => saving = false);
                          }
                        }
                      },
                child: Text(saving ? 'Đang lưu…' : 'Lưu'),
              ),
            ],
          ),
        ),
      );
    } finally {
      name.dispose();
      price.dispose();
    }
  }

  Future<void> _decide(String type, String id, bool confirm) async {
    if (_busyId != null) {
      return;
    }
    setState(() => _busyId = id);
    try {
      await _repository.decideOrder(type, id, confirm: confirm);
      if (mounted) setState(() => _orders = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không xử lý được đơn. Kiểm tra trạng thái và thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmDecision(String type, String id, bool confirm) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirm ? 'Xác nhận đã nhận thanh toán?' : 'Từ chối đơn?'),
        content: Text(
          confirm
              ? 'Gói cửa hàng có hiệu lực sau xác nhận; quảng cáo cùng loại đang chạy sẽ được nối tiếp. Hãy đối soát tiền trước.'
              : 'Đơn sẽ được đánh dấu từ chối.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (approved == true && mounted) await _decide(type, id, confirm);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Gói & đơn cửa hàng / quảng cáo'),
      actions: [
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              child: SizedBox(
                width: 900,
                height: 700,
                child: AdminOrderHistory(repository: _repository),
              ),
            ),
          ),
          child: const Text('Lịch sử đơn'),
        ),
      ],
    ),
    body:
        FutureBuilder<
          (
            List<Map<String, dynamic>>,
            List<Map<String, dynamic>>,
            List<PromotionPackage>,
            List<StorePackage>,
          )
        >(
          future: _orders,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(() => _orders = _load()),
                    child: const Text('Không tải được đơn. Thử lại'),
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            final (stores, promotions, packages, storePackages) =
                snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final pending = _load();
                setState(() => _orders = pending);
                await pending;
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  ResponsiveContent(
                    maxWidth: 900,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chỉ xác nhận sau khi đã kiểm tra thanh toán ngoài hệ thống.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gói cửa hàng (${stores.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        for (final order in stores) _card('stores', order),
                        const SizedBox(height: 18),
                        Text(
                          'Quảng cáo tin (${promotions.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        for (final order in promotions)
                          _card('promotions', order),
                        if (stores.isEmpty && promotions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Text('Không có đơn đang chờ.'),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Cấu hình gói tài khoản',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        for (final item in storePackages)
                          Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.monthlyPrice} đ / 30 ngày · ${item.dailyListingLimit} tin/ngày · ${item.activeListingLimit} tin hoạt động',
                              ),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: () => _editStorePackage(item),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Gói Đẩy Tin / Tin Ưu Tiên',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _editPackage(),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm gói'),
                            ),
                          ],
                        ),
                        for (final item in packages)
                          Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.kind == 'BUMP' ? 'Đẩy Tin' : 'Tin Ưu Tiên'} · ${item.durationDays} ngày · ${NumberFormat.decimalPattern('vi').format(num.parse(item.price))} đ · ${item.active ? 'Đang bán' : 'Tạm ngừng'}',
                              ),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: () => _editPackage(item),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
  );

  Widget _card(String type, Map<String, dynamic> order) {
    final id = order['id'] as String;
    final user = order['user'] as Map<String, dynamic>;
    final package = order['package'] as Map<String, dynamic>;
    final target = type == 'stores'
        ? (order['category'] as Map<String, dynamic>)['name'] as String
        : (order['listing'] as Map<String, dynamic>)['title'] as String;
    final amount = num.parse(order['amount'].toString());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Người mua: ${user['fullName']} · ${user['email']}'),
            Text(type == 'stores' ? 'Danh mục: $target' : 'Tin: $target'),
            Text('Giá: ${NumberFormat.decimalPattern('vi').format(amount)} đ'),
            Text(
              'Mã đơn: $id',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: _busyId == null
                      ? () => _confirmDecision(type, id, true)
                      : null,
                  child: const Text('Xác nhận đã thanh toán'),
                ),
                TextButton(
                  onPressed: _busyId == null
                      ? () => _confirmDecision(type, id, false)
                      : null,
                  child: const Text('Từ chối'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
