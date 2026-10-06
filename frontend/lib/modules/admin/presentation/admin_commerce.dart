import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../stores/data/store_repository.dart';

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
    )
  >
  _orders = _load();
  String? _busyId;

  Future<
    (
      List<Map<String, dynamic>>,
      List<Map<String, dynamic>>,
      List<PromotionPackage>,
    )
  >
  _load() async => (
    await _repository.pendingOrders('stores'),
    await _repository.pendingOrders('promotions'),
    await _repository.allPromotionPackages(),
  );

  Future<void> _editPackage([PromotionPackage? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final price = TextEditingController(text: item?.price ?? '');
    var kind = item?.kind ?? 'BUMP';
    var duration = item?.durationDays ?? 1;
    var active = item?.active ?? true;
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
                        items: const [1, 3, 7]
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
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
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
                  }
                },
                child: const Text('Lưu'),
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
              ? 'Gói hoặc quảng cáo sẽ có hiệu lực ngay sau khi xác nhận. Hãy đối soát tiền trước.'
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
    appBar: AppBar(title: const Text('Xác nhận đơn cửa hàng & quảng cáo')),
    body:
        FutureBuilder<
          (
            List<Map<String, dynamic>>,
            List<Map<String, dynamic>>,
            List<PromotionPackage>,
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
            final (stores, promotions, packages) = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => setState(() => _orders = _load()),
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
