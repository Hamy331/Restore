import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_preview_data.dart';
import 'admin_widgets.dart';

typedef _CatalogEntry = ({
  String id,
  String name,
  String description,
  bool active,
});

class AdminCatalogView extends StatefulWidget {
  const AdminCatalogView({super.key});
  @override
  State<AdminCatalogView> createState() => _AdminCatalogViewState();
}

class _AdminCatalogViewState extends State<AdminCatalogView> {
  int _tab = 0;
  String _query = '';
  final _groups = <List<_CatalogEntry>>[
    [
      (
        id: 'DM-01',
        name: 'Máy ảnh',
        description: 'Máy ảnh film, kỹ thuật số và phụ kiện',
        active: true,
      ),
      (
        id: 'DM-02',
        name: 'Nội thất',
        description: 'Bàn ghế, đèn và đồ trang trí',
        active: true,
      ),
      (
        id: 'DM-03',
        name: 'Thời trang',
        description: 'Quần áo, giày dép và phụ kiện',
        active: true,
      ),
      (
        id: 'DM-04',
        name: 'Sách',
        description: 'Sách đã qua sử dụng',
        active: false,
      ),
    ],
    [
      (id: 'TT-01', name: 'Mới', description: 'Chưa qua sử dụng', active: true),
      (
        id: 'TT-02',
        name: 'Như mới',
        description: 'Rất ít dấu vết sử dụng',
        active: true,
      ),
      (
        id: 'TT-03',
        name: 'Đã dùng – Tốt',
        description: 'Hoạt động tốt, có dấu vết sử dụng',
        active: true,
      ),
      (
        id: 'TT-04',
        name: 'Cần sửa chữa',
        description: 'Cần sửa chữa hoặc dùng làm linh kiện',
        active: true,
      ),
    ],
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AdminHeading(
        'Danh mục & tình trạng',
        'Sắp xếp nội dung để người mua dễ tìm đúng sản phẩm.',
        action: AdminButton(
          'Thêm ${_tab == 0 ? 'danh mục' : 'tình trạng'}',
          icon: Icons.add,
          primary: true,
          onPressed: () => _edit(),
        ),
      ),
      Wrap(
        spacing: 8,
        children: [
          for (final (i, name) in ['Danh mục', 'Tình trạng sản phẩm'].indexed)
            ChoiceChip(
              label: Text(name),
              selected: _tab == i,
              onSelected: (_) => setState(() => _tab = i),
            ),
        ],
      ),
      const SizedBox(height: 20),
      AdminSearch(
        hint: 'Tìm tên hoặc mô tả',
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: 20),
      AdminTable(
        columns: const ['TÊN', 'MÔ TẢ', 'TRẠNG THÁI', ''],
        rows: [
          for (final x in _groups[_tab].where(
            (x) => '${x.name} ${x.description}'.toLowerCase().contains(
              _query.toLowerCase(),
            ),
          ))
            [
              Text(x.name),
              SizedBox(width: 300, child: Text(x.description)),
              AdminBadge(x.active ? 'Hoạt động' : 'Tạm ngừng'),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _edit(x),
                    child: const Text('Chỉnh sửa'),
                  ),
                  TextButton(
                    onPressed: () => adminDialog(
                      context,
                      title: x.active ? 'Ngừng sử dụng?' : 'Kích hoạt lại?',
                      width: 460,
                      child: Builder(
                        builder: (dialogContext) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '“${x.name}” ${x.active ? 'sẽ không xuất hiện trong lựa chọn cho tin mới' : 'sẽ xuất hiện trong lựa chọn cho tin mới'}. Tin đã đăng giữ thông tin cũ trong bản mẫu.',
                            ),
                            const SizedBox(height: 20),
                            AdminButton(
                              'Xác nhận',
                              onPressed: () {
                                _save((
                                  id: x.id,
                                  name: x.name,
                                  description: x.description,
                                  active: !x.active,
                                ));
                                Navigator.pop(dialogContext);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: Text(x.active ? 'Ngừng sử dụng' : 'Kích hoạt'),
                  ),
                ],
              ),
            ],
        ],
      ),
    ],
  );

  void _save(_CatalogEntry item) {
    setState(() {
      final list = _groups[_tab];
      final index = list.indexWhere((x) => x.id == item.id);
      if (index < 0) {
        list.add(item);
      } else {
        list[index] = item;
      }
    });
    context.read<AdminPreviewCubit>().record(
      item.id,
      'Cập nhật ${_tab == 0 ? 'danh mục' : 'tình trạng'}',
      item.name,
    );
    adminNotice(context);
  }

  Future<void> _edit([_CatalogEntry? item]) async {
    final values = await adminDialog<List<String>>(
      context,
      title: item == null ? 'Thêm mới' : 'Chỉnh sửa ${item.name}',
      width: 520,
      child: AdminTextForm(
        labels: const ['Tên', 'Mô tả'],
        initial: [item?.name ?? '', item?.description ?? ''],
        validateName: (name) =>
            _groups[_tab].any(
              (x) =>
                  x.id != item?.id &&
                  x.name.toLowerCase() == name.toLowerCase(),
            )
            ? 'Tên đã tồn tại.'
            : null,
      ),
    );
    if (values == null || !mounted) return;
    _save((
      id: item?.id ?? 'CAT-${DateTime.now().microsecondsSinceEpoch}',
      name: values[0],
      description: values[1],
      active: item?.active ?? true,
    ));
  }
}

class AdminTextForm extends StatefulWidget {
  const AdminTextForm({
    required this.labels,
    required this.initial,
    this.validateName,
    super.key,
  });
  final List<String> labels, initial;
  final String? Function(String)? validateName;
  @override
  State<AdminTextForm> createState() => _AdminTextFormState();
}

class _AdminTextFormState extends State<AdminTextForm> {
  final _form = GlobalKey<FormState>();
  late final _controllers = [
    for (final value in widget.initial) TextEditingController(text: value),
  ];
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, label) in widget.labels.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _controllers[i],
              maxLines: i == 0 ? 1 : 3,
              maxLength: i == 0 ? 100 : 500,
              decoration: InputDecoration(labelText: label),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập $label.';
                }
                return i == 0 ? widget.validateName?.call(v.trim()) : null;
              },
            ),
          ),
        AdminButton(
          'Lưu bản mẫu',
          primary: true,
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, [
                for (final c in _controllers) c.text.trim(),
              ]);
            }
          },
        ),
      ],
    ),
  );
}
