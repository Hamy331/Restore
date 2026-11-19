import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/media_url.dart';
import '../../../shared/widgets/app_local_image.dart';
import '../data/admin_repository.dart';
import 'admin_widgets.dart';

const _statuses = <(String, String)>[
  ('PENDING', 'Chờ duyệt'),
  ('APPROVED', 'Đã duyệt'),
  ('REJECTED', 'Từ chối'),
  ('STOPPED', 'Shop đã dừng'),
  ('ALL', 'Tất cả'),
];

const _reasons = <(String, String)>[
  ('WRONG_SIZE', 'Sai kích thước ảnh (cần 2:1, 1200×600)'),
  ('MISLEADING_PRICE', 'Giá hoặc ưu đãi gây hiểu lầm'),
  ('BRAND_MISUSE', 'Dùng logo, thương hiệu không thuộc shop'),
  ('PROHIBITED', 'Nội dung bị cấm'),
  ('TOO_MUCH_TEXT', 'Quá nhiều chữ trên ảnh'),
  ('OTHER', 'Lý do khác (ghi rõ)'),
];

String _reasonLabel(String? code) =>
    _reasons.where((r) => r.$1 == code).map((r) => r.$2).firstOrNull ??
    code ??
    '';

/// Duyệt poster shop: `GET /admin/shop-posters?status=`,
/// `POST /admin/shop-posters/:id/approve`, `POST /admin/shop-posters/:id/reject`
class AdminShopPostersView extends StatefulWidget {
  const AdminShopPostersView({this.repository, super.key});
  final AdminRepository? repository;
  @override
  State<AdminShopPostersView> createState() => _AdminShopPostersViewState();
}

class _AdminShopPostersViewState extends State<AdminShopPostersView> {
  late final _repository = widget.repository ?? AdminRepository();
  String _status = 'PENDING', _error = '';
  int _pending = 0;
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true, _mutating = false;
  int _request = 0;

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
      final response = await _repository.dio.get<Map<String, dynamic>>(
        '/admin/shop-posters',
        queryParameters: {'status': _status},
      );
      final data = Map<String, dynamic>.from(response.data!['data'] as Map);
      if (!mounted || request != _request) return;
      setState(() {
        _pending = (data['pendingCount'] as num?)?.toInt() ?? 0;
        _items = [
          for (final item in data['items'] as List)
            Map<String, dynamic>.from(item as Map),
        ];
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = _repository.message(error));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _perform(Future<void> Function() work, String done) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await work();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      await _load();
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

  void _approve(Map<String, dynamic> poster) => _perform(
    () => _repository.dio.post<void>(
      '/admin/shop-posters/${poster['id']}/approve',
    ),
    'Đã duyệt poster "${poster['title']}".',
  );

  Future<void> _reject(Map<String, dynamic> poster) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _RejectDialog(title: '${poster['title']}'),
    );
    if (result == null) return;
    await _perform(
      () => _repository.dio.post<void>(
        '/admin/shop-posters/${poster['id']}/reject',
        data: {
          'reason': result.$1,
          if (result.$2.trim().isNotEmpty) 'note': result.$2.trim(),
        },
      ),
      'Đã từ chối poster "${poster['title']}".',
    );
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_loading || _mutating) const LinearProgressIndicator(),
        const AdminHeading(
          'Poster shop',
          'Shop gói Cửa hàng gửi poster 2:1; duyệt rồi poster mới hiện ở trang shop và Shop uy tín. '
              'Từ chối 3 lần trong 30 ngày thì shop bị khóa gửi 7 ngày.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in _statuses)
              ChoiceChip(
                key: ValueKey('admin-poster-status-$value'),
                label: Text(
                  value == 'PENDING' && _pending > 0
                      ? '$label ($_pending)'
                      : label,
                ),
                selected: _status == value,
                onSelected: (_) {
                  setState(() => _status = value);
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_error.isNotEmpty)
          Column(
            children: [
              Text(_error),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          )
        else if (!_loading && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('Không có poster nào.')),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 3
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final poster in _items)
                    SizedBox(width: width, child: _card(poster)),
                ],
              );
            },
          ),
      ],
    ),
  );

  Widget _card(Map<String, dynamic> poster) {
    final shop = Map<String, dynamic>.from(poster['shop'] as Map? ?? const {});
    final listing = poster['listing'] is Map
        ? Map<String, dynamic>.from(poster['listing'] as Map)
        : null;
    final format = DateFormat('dd/MM HH:mm');
    String date(Object? value) {
      final parsed = DateTime.tryParse('${value ?? ''}');
      return parsed == null ? '-' : format.format(parsed.toLocal());
    }

    final image = resolveMediaUrl('${poster['imageUrl'] ?? ''}');
    final pending = poster['status'] == 'PENDING' && poster['state'] != 'ENDED';
    return AdminPanel(
      key: ValueKey('admin-poster-${poster['id']}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 2,
              child: image == null || image.isEmpty
                  ? const ColoredBox(color: AppColors.cream)
                  : AppLocalImage(path: image, cacheWidth: 900),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${poster['title']}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '${shop['name']} · ${shop['verified'] == true ? 'đã xác minh' : 'chưa xác minh'} · gói ${shop['planTier']}',
          ),
          Text('${shop['ownerEmail'] ?? ''}'),
          const SizedBox(height: 6),
          Text(
            'Chạy: ${date(poster['startsAt'])} → ${date(poster['endsAt'])} (${poster['days']} ngày)',
          ),
          Text(
            listing == null
                ? 'Bấm vào mở trang shop'
                : 'Bấm vào mở tin: ${listing['title']}${listing['available'] == false ? ' (tin không còn bán)' : ''}',
          ),
          Text(
            'Gửi lúc: ${date(poster['updatedAt'] ?? poster['createdAt'])} · trạng thái ${poster['state']}',
          ),
          if (poster['rejectReason'] != null)
            Text(
              'Lý do từ chối: ${_reasonLabel(poster['rejectReason'] as String?)}'
              '${poster['rejectNote'] != null ? ' · ${poster['rejectNote']}' : ''}',
              style: const TextStyle(color: AppColors.error),
            ),
          if (pending) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                AdminButton(
                  'Duyệt',
                  primary: true,
                  onPressed: _mutating ? null : () => _approve(poster),
                ),
                AdminButton(
                  'Từ chối',
                  danger: true,
                  onPressed: _mutating ? null : () => _reject(poster),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.title});
  final String title;
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  String _reason = _reasons.first.$1;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsNote = _reason == 'OTHER' && _note.text.trim().isEmpty;
    return AlertDialog(
      title: Text('Từ chối "${widget.title}"'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (value) =>
                    setState(() => _reason = value ?? _reason),
                child: Column(
                  children: [
                    for (final (value, label) in _reasons)
                      RadioListTile<String>(
                        value: value,
                        title: Text(label),
                        dense: true,
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText:
                      'Ghi chú cho shop (không bắt buộc, trừ "Lý do khác")',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: needsNote
              ? null
              : () => Navigator.pop(context, (_reason, _note.text)),
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}
