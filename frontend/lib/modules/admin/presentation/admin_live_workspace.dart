import '../../stores/data/store_repository.dart';
import 'package:file_selector/file_selector.dart' show openFile, XTypeGroup;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_local_image.dart';
import '../data/admin_repository.dart';
import 'admin_commerce.dart';
import 'admin_shop_posters.dart';
import 'admin_widgets.dart';

const _sections = [
  'Tổng quan',
  'Kiểm duyệt tin',
  'Báo cáo vi phạm',
  'Người dùng',
  'Danh mục & tình trạng',
  'Gói & đơn mua',
  'Bài viết',
  'Hỗ trợ người dùng',
  'Tri thức',
  'Nhật ký quản trị',
  'Poster shop',
];
const _resources = [
  'dashboard',
  'listings',
  'reports',
  'users',
  'catalog',
  'store-packages',
  'posts',
  'tickets',
  'knowledge',
  'audit',
  'shop-posters',
];
String _label(dynamic value) => value is Map
    ? '${value['vi'] ?? value.values.firstOrNull ?? ''}'
    : '${value ?? ''}';

class AdminLiveWorkspace extends StatefulWidget {
  const AdminLiveWorkspace({
    this.repository,
    this.commerceRepository,
    super.key,
  });
  final AdminRepository? repository;
  final StoreRepository? commerceRepository;
  @override
  State<AdminLiveWorkspace> createState() => _AdminLiveWorkspaceState();
}

class _AdminLiveWorkspaceState extends State<AdminLiveWorkspace> {
  late final _repository = widget.repository ?? AdminRepository();
  int _section = 0, _page = 1, _request = 0;
  dynamic _data;
  String _error = '', _query = '', _name = '';
  bool _loading = false, _mutating = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _repository.get(
        _resources[_section],
        page: _page,
        q: _query,
      );
      if (!mounted || request != _request) return;
      setState(() => _data = data);
      if (_name.isEmpty) {
        final me = await _repository.get('me');
        if (mounted) setState(() => _name = _label(me['fullName']));
      }
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = _repository.message(error));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _select(int section) {
    setState(() {
      _section = section;
      _page = 1;
      _query = '';
      _data = null;
    });
    _load();
  }

  Future<void> _perform(Future<void> Function() work) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await work();
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_repository.message(error))));
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<bool?> _edit(
    String title,
    Map<String, dynamic> values,
    Map<String, List<String>> choices,
    Future<void> Function(Map<String, dynamic>) save, {
    bool upload = false,
  }) async {
    return adminDialog<bool>(
      context,
      title: title,
      child: _LiveEditor(
        values: values,
        choices: choices,
        repository: _repository,
        upload: upload,
        onSave: (data) async {
          await save(data);
          if (mounted) await _load();
        },
      ),
    );
  }

  /// Bản sửa chờ duyệt của tin đã duyệt (tin vẫn hiện bản cũ trong lúc chờ)
  Map? _pendingEdit(Map<String, dynamic> row) =>
      row['pendingEdit'] is Map && row['pendingEdit']['status'] == 'PENDING'
      ? row['pendingEdit'] as Map
      : null;

  Future<void> _decision(Map<String, dynamic> row, {bool user = false}) async {
    final edit = user ? null : _pendingEdit(row);
    final actions = user
        ? (row['status'] == 'BANNED'
              ? ['RESTORE']
              : [
                  'WARN',
                  'SUSPEND',
                  'BAN',
                  if (row['status'] == 'SUSPENDED') 'RESTORE',
                ])
        : row['status'] == 'PENDING'
        ? ['APPROVE', 'REJECT', 'REQUEST_CHANGES']
        : edit != null
        ? ['APPROVE', 'REJECT', 'REQUEST_CHANGES', 'REMOVE']
        : ['REMOVE'];
    await _edit(
      user
          ? 'Xử lý tài khoản'
          : edit != null
          ? 'Duyệt bản sửa (gỡ tin: REMOVE)'
          : 'Quyết định kiểm duyệt',
      {'action': actions.first, 'reason': '', if (user) 'days': 7},
      {'action': actions},
      (data) => _repository.save(
        '${user ? 'users' : 'listings'}/${Uri.encodeComponent(row['id'])}/${user ? 'action' : 'decision'}',
        {
          ...data,
          // Duyệt / từ chối bản sửa: gửi updatedAt của bản sửa
          'updatedAt': edit != null && data['action'] != 'REMOVE'
              ? edit['updatedAt']
              : row['updatedAt'],
        },
      ),
    );
  }

  Future<void> _report(Map<String, dynamic> row) async {
    await _perform(() async {
      final target = await _repository.get(
        'reports/${Uri.encodeComponent(row['id'])}/target',
      );
      if (!mounted) return;
      final actions = row['targetType'] == 'USER'
          ? ['DISMISS', 'WARN', 'SUSPEND', 'BAN']
          : ['DISMISS', 'KEEP', if (target?['status'] == 'AVAILABLE') 'REMOVE'];
      await _edit(
        'Xử lý ${row['id']}',
        {
          'action': actions.first,
          'reason': '',
          if (row['targetType'] == 'USER') 'days': 7,
        },
        {'action': actions},
        (data) => _repository
            .save('reports/${Uri.encodeComponent(row['id'])}/resolve', {
              ...data,
              'updatedAt': row['updatedAt'],
              'targetUpdatedAt': target?['updatedAt'],
            }),
      );
    });
  }

  Future<void> _catalog([
    Map<String, dynamic>? row,
    bool condition = false,
  ]) async {
    final metadata = row?['metadata'] as Map?;
    dynamic currentName;
    if (condition) {
      currentName = row == null ? null : row['name'];
    } else {
      currentName = metadata == null
          ? (row == null ? null : row['name'])
          : metadata['name'];
    }
    await _edit(
      condition ? 'Tình trạng sản phẩm' : 'Danh mục',
      {
        if (row == null) 'id': '',
        'name': _label(currentName),
        if (!condition) 'description': _label(metadata?['description']),
        'active': row?['active'] ?? true,
      },
      {},
      (data) => _repository.save(
        condition
            ? 'conditions/${row!['condition']}'
            : row == null
            ? 'categories'
            : 'categories/${Uri.encodeComponent(row['id'])}',
        data,
        update: row != null,
      ),
    );
  }

  Future<void> _post([Map<String, dynamic>? row]) async {
    await _edit(
      row == null ? 'Viết bài' : 'Sửa bài viết',
      {
        'title': row?['title'] ?? '',
        'slug': row?['slug'] ?? '',
        'category': row?['category'] ?? 'Hướng dẫn',
        'content': row?['content'] ?? '',
        'coverUrl': row?['coverUrl'] ?? '',
        'listingIds': (row?['listingIds'] as List? ?? []).join(','),
        'status': row?['status'] ?? 'DRAFT',
      },
      {
        'status': ['DRAFT', 'PUBLISHED', 'HIDDEN', 'ARCHIVED'],
      },
      (data) => _repository.save(row == null ? 'posts' : 'posts/${row['id']}', {
        ...data,
        'listingIds': '${data['listingIds']}'
            .split(',')
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList(),
        if (row != null) 'updatedAt': row['updatedAt'],
      }, update: row != null),
      upload: true,
    );
  }

  Future<void> _previewPost(Map<String, dynamic> row) async {
    await adminDialog<void>(
      context,
      title: row['title'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (row['coverUrl'] is String &&
              (row['coverUrl'] as String).isNotEmpty)
            SizedBox(
              height: 240,
              width: double.infinity,
              child: AppLocalImage(
                path:
                    '${Uri.parse(AppEnvironment.apiBaseUrl).origin}${row['coverUrl']}',
              ),
            ),
          const SizedBox(height: 16),
          Text(row['category']),
          const SizedBox(height: 12),
          SelectableText(row['content']),
        ],
      ),
    );
  }

  Future<void> _uploadKnowledge() async {
    await _perform(() async {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Tài liệu văn bản',
            extensions: ['txt', 'md'],
            uniformTypeIdentifiers: ['public.plain-text'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 100000) {
        throw const FormatException('Tài liệu tối đa 100 KB');
      }
      await _repository.uploadKnowledge(file.name, await file.readAsString());
    });
  }

  Future<void> _knowledge([Map<String, dynamic>? row]) async {
    await _edit(
      'Tài liệu tri thức',
      {
        'title': row?['title'] ?? '',
        'content': row?['content'] ?? '',
        'active': row?['active'] ?? true,
      },
      {},
      (data) => _repository.save(
        row == null ? 'knowledge' : 'knowledge/${row['id']}',
        {...data, if (row != null) 'updatedAt': row['updatedAt']},
        update: row != null,
      ),
    );
  }

  Future<void> _ticket(Map<String, dynamic> row) async {
    final messages = (row['messages'] as List).cast<Map>();
    await adminDialog<void>(
      context,
      title: row['subject'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final message in messages)
            ListTile(
              title: Text(
                message['isAdmin'] == true ? 'Quản trị viên' : 'Người dùng',
              ),
              subtitle: Text(_label(message['content'])),
            ),
          if (row['status'] == 'OPEN')
            AdminButton(
              'Trả lời',
              onPressed: () async {
                final saved = await _edit(
                  'Phản hồi hỗ trợ',
                  {'content': ''},
                  {},
                  (data) => _repository.save('tickets/${row['id']}/reply', {
                    ...data,
                    'updatedAt': row['updatedAt'],
                  }),
                );
                if (saved == true && mounted) Navigator.pop(context);
              },
            ),
          AdminButton(
            row['status'] == 'OPEN' ? 'Đánh dấu đã giải quyết' : 'Mở lại',
            onPressed: () => _perform(() async {
              await _repository.save('tickets/${row['id']}/status', {
                'status': row['status'] == 'OPEN' ? 'RESOLVED' : 'OPEN',
                'updatedAt': row['updatedAt'],
              });
              if (mounted) Navigator.pop(context);
            }),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> row) {
    final actions = <Widget>[];
    switch (_section) {
      case 1:
        if (['PENDING', 'AVAILABLE'].contains(row['status']) ||
            _pendingEdit(row) != null) {
          actions.add(
            TextButton(
              onPressed: () => _decision(row),
              child: const Text('Ra quyết định'),
            ),
          );
        }
      case 2:
        if (row['status'] == 'OPEN') {
          actions.add(
            TextButton(
              onPressed: () => _report(row),
              child: const Text('Xử lý báo cáo'),
            ),
          );
        }
      case 3:
        if (row['status'] != 'UNVERIFIED') {
          actions.add(
            TextButton(
              onPressed: () => _decision(row, user: true),
              child: const Text('Xử lý tài khoản'),
            ),
          );
        }
      case 6:
        actions.add(
          TextButton(
            onPressed: () => _previewPost(row),
            child: const Text('Xem trước'),
          ),
        );
        actions.add(
          TextButton(
            onPressed: () => _post(row),
            child: const Text('Chỉnh sửa'),
          ),
        );
      case 7:
        actions.add(
          TextButton(
            onPressed: () => _ticket(row),
            child: const Text('Mở yêu cầu'),
          ),
        );
      case 8:
        actions.addAll([
          TextButton(
            onPressed: () => _knowledge(row),
            child: const Text('Chỉnh sửa'),
          ),
          TextButton(
            onPressed: () => _perform(
              () => _repository.save('knowledge/${row['id']}/sync', {
                'updatedAt': row['updatedAt'],
              }),
            ),
            child: const Text('Lập chỉ mục'),
          ),
          TextButton(
            onPressed: () => _edit(
              'Xác nhận xóa',
              {'reason': ''},
              {},
              (_) => _repository.save('knowledge/${row['id']}', {
                'updatedAt': row['updatedAt'],
              }, delete: true),
            ),
            child: const Text('Xóa tài liệu'),
          ),
        ]);
    }
    final edit = _section == 1 ? _pendingEdit(row) : null;
    final title = _label(
      row['title'] ??
          row['subject'] ??
          row['fullName'] ??
          row['action'] ??
          row['reason'] ??
          row['id'],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (row['status'] != null)
              Text('Trạng thái: ${_valueLabel(row['status'])}'),
            if (edit != null) ...[
              Text(
                'Bản sửa chờ duyệt (tin vẫn hiện bản cũ)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (edit['title'] != row['title'])
                Text('Tiêu đề mới: ${edit['title']}'),
              if ('${edit['price']}' != '${row['price']}')
                Text('Giá mới: ${edit['price']}'),
              if (edit['description'] != row['description'])
                Text('Mô tả mới: ${edit['description']}'),
              if ('${edit['images']}' != '${row['images']}')
                Text('Ảnh: ${(edit['images'] as List?)?.length ?? 0} ảnh mới'),
            ],
            if (row['email'] != null) Text(row['email']),
            if (row['owner'] is Map)
              Text('Người bán: ${row['owner']['fullName']}'),
            if (row['description'] != null) Text(row['description']),
            if (row['evidence'] != null) Text('Bằng chứng: ${row['evidence']}'),
            if (row['targetType'] != null)
              Text('Đối tượng: ${row['targetType']} · ${row['targetId']}'),
            if (row['resolution'] != null)
              Text('Kết luận: ${row['resolution']}'),
            if (row['reason'] != null) Text('Lý do: ${row['reason']}'),
            if (row['actorId'] != null)
              Text('Admin: ${row['actorId']} · ${row['createdAt']}'),
            if (_section == 8)
              Text(
                row['syncedAt'] == null
                    ? 'Chưa lập chỉ mục'
                    : 'Đã lập chỉ mục: ${row['syncedAt']}',
              ),
            if (row['images'] is List)
              Wrap(
                spacing: 8,
                children: [
                  for (final url in (row['images'] as List))
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: AppLocalImage(
                        path:
                            '${Uri.parse(AppEnvironment.apiBaseUrl).origin}$url',
                      ),
                    ),
                ],
              ),
            if (actions.isNotEmpty) Wrap(spacing: 8, children: actions),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_section == 5) {
      return AdminCommerceView(repository: widget.commerceRepository);
    }
    if (_section == 10) {
      return AdminShopPostersView(repository: _repository);
    }
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_data == null) return const SizedBox.shrink();
    final rows = _data is Map && _data['items'] is List
        ? (_data['items'] as List)
        : <dynamic>[];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loading || _mutating) const LinearProgressIndicator(),
          AdminHeading(
            _sections[_section],
            'Dữ liệu được lưu trên hệ thống.',
            action: switch (_section) {
              4 => AdminButton('Thêm danh mục', onPressed: () => _catalog()),
              6 => AdminButton('Viết bài', onPressed: () => _post()),
              8 => AdminButton('Thêm tài liệu', onPressed: () => _knowledge()),
              _ => null,
            },
          ),
          if ([1, 3].contains(_section))
            TextField(
              key: ValueKey(_section),
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                _query = value;
                _page = 1;
                _load();
              },
            ),
          const SizedBox(height: 16),
          if (_section == 8)
            TextButton(
              onPressed: () => _perform(
                () => _repository.save('knowledge/catalog-sync', {}),
              ),
              child: const Text('Đồng bộ catalog vào kho tri thức'),
            ),
          if (_section == 8)
            TextButton.icon(
              onPressed: _uploadKnowledge,
              icon: const Icon(Icons.upload_file),
              label: const Text('Tải TXT / Markdown, tối đa 100 KB'),
            ),
          if (_section == 0) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final entry in (_data as Map).entries.where(
                  (entry) => entry.key != 'logs',
                ))
                  SizedBox(
                    width: 220,
                    child: AdminPanel(
                      child: Text('${_valueLabel(entry.key)}\n${entry.value}'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            for (final row in _data['logs'] as List)
              _card(Map<String, dynamic>.from(row)),
          ] else if (_section == 4) ...[
            for (final row in _data['categories'] as List)
              ListTile(
                title: Text(_label(row['name'])),
                subtitle: Text(
                  row['active'] == true ? 'Đang sử dụng' : 'Ngừng sử dụng',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _catalog(Map<String, dynamic>.from(row)),
              ),
            const Divider(),
            const Text('Tình trạng sản phẩm'),
            for (final row in _data['conditions'] as List)
              ListTile(
                title: Text(_label(row['name'])),
                subtitle: Text(
                  row['active'] == true ? 'Đang sử dụng' : 'Ngừng sử dụng',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _catalog(Map<String, dynamic>.from(row), true),
              ),
          ] else ...[
            if (rows.isEmpty)
              const AdminEmpty(message: 'Chưa có dữ liệu trong mục này.'),
            for (final row in rows) _card(Map<String, dynamic>.from(row)),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: _page > 1
                      ? () {
                          _page--;
                          _load();
                        }
                      : null,
                  child: const Text('Trang trước'),
                ),
                Text('$_page'),
                TextButton(
                  onPressed: _page * 25 < (_data['total'] as int? ?? 0)
                      ? () {
                          _page++;
                          _load();
                        }
                      : null,
                  child: const Text('Trang sau'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _menu(bool drawer) => ListView(
    children: [
      const ListTile(title: Text('ReStore · Quản trị')),
      for (final (index, title) in _sections.indexed)
        ListTile(
          selected: index == _section,
          title: Text(title),
          onTap: () {
            if (drawer) Navigator.pop(context);
            _select(index);
          },
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => Scaffold(
      appBar: AppBar(
        title: Text('Quản trị · ${_name.isEmpty ? 'Đang tải' : _name}'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Về ứng dụng'),
          ),
        ],
      ),
      drawer: size.maxWidth < 1000 ? Drawer(child: _menu(true)) : null,
      body: Row(
        children: [
          if (size.maxWidth >= 1000) SizedBox(width: 235, child: _menu(false)),
          Expanded(
            child: AbsorbPointer(absorbing: _mutating, child: _body()),
          ),
        ],
      ),
    ),
  );
}

String _valueLabel(dynamic value) =>
    const <String, String>{
      'APPROVE': 'Duyệt tin',
      'REJECT': 'Từ chối',
      'REQUEST_CHANGES': 'Yêu cầu chỉnh sửa',
      'REMOVE': 'Gỡ tin',
      'WARN': 'Cảnh báo',
      'SUSPEND': 'Đình chỉ',
      'BAN': 'Cấm tài khoản',
      'RESTORE': 'Khôi phục',
      'DISMISS': 'Bác báo cáo',
      'KEEP': 'Giữ tin',
      'OPEN': 'Chờ xử lý',
      'RESOLVED': 'Đã xử lý',
      'DISMISSED': 'Đã bác bỏ',
      'PENDING': 'Chờ duyệt',
      'AVAILABLE': 'Đang hiển thị',
      'REJECTED': 'Bị từ chối',
      'HIDDEN': 'Đang ẩn',
      'DRAFT': 'Nháp',
      'PUBLISHED': 'Đã xuất bản',
      'ARCHIVED': 'Lưu trữ',
      'ACTIVE': 'Hoạt động',
      'BANNED': 'Đã cấm',
      'SUSPENDED': 'Đình chỉ',
      'pendingListings': 'Tin chờ duyệt',
      'openReports': 'Báo cáo chưa xử lý',
      'activeUsers': 'Thành viên hoạt động',
      'activeListings': 'Tin đang hiển thị',
      'pendingStores': 'Đơn cửa hàng chờ xác nhận',
      'pendingPromotions': 'Đơn quảng cáo chờ xác nhận',
      'promotionRevenue': 'Doanh thu quảng cáo đã xác nhận',
    }['$value'] ??
    '$value';

const _fieldLabels = {
  'id': 'Mã danh mục',
  'name': 'Tên',
  'description': 'Mô tả',
  'active': 'Đang sử dụng',
  'title': 'Tiêu đề',
  'slug': 'Đường dẫn bài viết',
  'category': 'Chuyên mục',
  'content': 'Nội dung',
  'coverUrl': 'Ảnh bìa đã tải',
  'listingIds': 'ID tin quảng cáo (cách nhau bằng dấu phẩy)',
  'status': 'Trạng thái',
  'action': 'Quyết định',
  'reason': 'Lý do / xác nhận',
  'days': 'Số ngày đình chỉ',
};

class _LiveEditor extends StatefulWidget {
  const _LiveEditor({
    required this.values,
    required this.choices,
    required this.repository,
    required this.onSave,
    this.upload = false,
  });
  final Map<String, dynamic> values;
  final Map<String, List<String>> choices;
  final AdminRepository repository;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final bool upload;
  @override
  State<_LiveEditor> createState() => _LiveEditorState();
}

class _LiveEditorState extends State<_LiveEditor> {
  late final _values = Map<String, dynamic>.from(widget.values);
  late final _controllers = {
    for (final entry in widget.values.entries.where((e) => e.value is! bool))
      entry.key: TextEditingController(text: '${entry.value}'),
  };
  bool _busy = false, _dirty = false, _closing = false;
  String _error = '';
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final data = {
        for (final entry in _values.entries)
          entry.key: entry.value is bool
              ? entry.value
              : entry.value is int
              ? int.parse(_controllers[entry.key]!.text)
              : _controllers[entry.key]!.text,
      };
      await widget.onSave(data);
      if (mounted) {
        setState(() => _closing = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = widget.repository.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: (!_dirty || _closing) && !_busy,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || _busy) return;
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Bỏ thay đổi chưa lưu?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Tiếp tục'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        ),
      );
      if (discard == true && mounted) {
        setState(() => _closing = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _values.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: entry.value is bool
                ? SwitchListTile(
                    title: Text(_fieldLabels[entry.key] ?? entry.key),
                    value: _values[entry.key],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _values[entry.key] = value;
                            _dirty = true;
                          }),
                  )
                : widget.choices.containsKey(entry.key)
                ? DropdownButtonFormField<String>(
                    initialValue: _controllers[entry.key]!.text,
                    decoration: InputDecoration(
                      labelText: _fieldLabels[entry.key] ?? entry.key,
                    ),
                    items: [
                      for (final value in widget.choices[entry.key]!)
                        DropdownMenuItem(
                          value: value,
                          child: Text(_valueLabel(value)),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) {
                            _controllers[entry.key]!.text = value!;
                            _dirty = true;
                          },
                  )
                : TextFormField(
                    controller: _controllers[entry.key],
                    readOnly: _busy || entry.key == 'coverUrl',
                    maxLines: entry.key == 'content'
                        ? 10
                        : entry.key == 'reason' || entry.key == 'description'
                        ? 3
                        : 1,
                    keyboardType: entry.value is int
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _fieldLabels[entry.key] ?? entry.key,
                    ),
                    onChanged: (_) => _dirty = true,
                  ),
          ),
        if (widget.upload)
          TextButton.icon(
            icon: const Icon(Icons.upload),
            label: const Text('Tải ảnh bìa (JPEG/PNG/WebP, tối đa 5 MB)'),
            onPressed: _busy
                ? null
                : () async {
                    final file = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1600,
                      imageQuality: 85,
                    );
                    if (file == null || !mounted) return;
                    setState(() => _busy = true);
                    try {
                      final bytes = await file.readAsBytes();
                      if (bytes.length > 5 * 1024 * 1024) {
                        throw const FormatException('Ảnh quá lớn');
                      }
                      final url = await widget.repository.uploadCover(bytes);
                      if (mounted) {
                        setState(() {
                          _controllers['coverUrl']!.text = url;
                          _dirty = true;
                        });
                      }
                    } catch (error) {
                      if (mounted) {
                        setState(
                          () => _error = widget.repository.message(error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
          ),
        if (_error.isNotEmpty)
          Text(_error, style: const TextStyle(color: AppColors.error)),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Đang lưu…' : 'Lưu vào hệ thống'),
        ),
      ],
    ),
  );
}
