import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_catalog.dart';
import 'admin_preview_data.dart';
import 'admin_widgets.dart';

class AdminSupportView extends StatefulWidget {
  const AdminSupportView({super.key});
  @override
  State<AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<AdminSupportView> {
  int _selected = 0;
  final _reply = TextEditingController();
  final _replies = <int, List<String>>{};
  final _resolved = <int>{};
  final _tickets = const [
    (
      'HT-012',
      'Minh Anh',
      'Tôi đã thanh toán gói Boost nhưng tin chưa được đẩy.',
    ),
    ('HT-011', 'Gia Hân', 'Tôi cần bổ sung ảnh như thế nào để tin được duyệt?'),
  ];
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AdminHeading(
        'Hỗ trợ người dùng',
        'Hội thoại mẫu được chuyển từ chatbot đến quản trị viên.',
      ),
      AdminTwoColumns(
        equal: true,
        left: AdminPanel(
          child: Column(
            children: [
              for (final (i, ticket) in _tickets.indexed)
                ListTile(
                  selected: _selected == i,
                  selectedTileColor: AppColors.cream,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(ticket.$2),
                  subtitle: Text(
                    '${ticket.$1} · ${_resolved.contains(i) ? 'Đã giải quyết' : 'Chờ hỗ trợ'}',
                  ),
                  onTap: () => setState(() {
                    _selected = i;
                    _reply.clear();
                  }),
                ),
            ],
          ),
        ),
        right: AdminPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tickets[_selected].$2,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              AdminBadge(
                _resolved.contains(_selected) ? 'Đã giải quyết' : 'Chờ hỗ trợ',
              ),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_tickets[_selected].$3),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Chatbot đã chuyển yêu cầu để quản trị viên hỗ trợ.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              for (final reply in _replies[_selected] ?? <String>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Linh Nguyễn · Bản mẫu\n$reply'),
                  ),
                ),
              if (!_resolved.contains(_selected)) ...[
                TextField(
                  controller: _reply,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung trả lời mẫu',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminButton(
                      'Lưu trả lời mẫu',
                      primary: true,
                      onPressed: () {
                        if (_reply.text.trim().isEmpty) {
                          adminNotice(
                            context,
                            'Nhập nội dung trả lời trước khi lưu.',
                          );
                          return;
                        }
                        setState(() {
                          (_replies[_selected] ??= []).add(_reply.text.trim());
                          _reply.clear();
                        });
                        adminNotice(
                          context,
                          'Đã lưu trả lời mẫu trong phiên. Không gửi tin nhắn thật.',
                        );
                      },
                    ),
                    AdminButton(
                      'Đánh dấu đã giải quyết',
                      onPressed: () {
                        setState(() => _resolved.add(_selected));
                        context.read<AdminPreviewCubit>().record(
                          _tickets[_selected].$1,
                          'Giải quyết hỗ trợ mẫu',
                          _tickets[_selected].$2,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class AdminKnowledgeView extends StatefulWidget {
  const AdminKnowledgeView({super.key});
  @override
  State<AdminKnowledgeView> createState() => _AdminKnowledgeViewState();
}

class _AdminKnowledgeViewState extends State<AdminKnowledgeView> {
  final _documents = <({String name, String description})>[
    (
      name: 'Hướng dẫn giao dịch an toàn.pdf',
      description: 'Hẹn gặp, kiểm tra hàng và bảo vệ thông tin cá nhân.',
    ),
    (
      name: 'Quy định đăng tin.pdf',
      description: 'Nội dung được phép và hướng dẫn kiểm duyệt.',
    ),
  ];
  bool _syncing = false;
  String _syncStatus = 'Chưa kết nối';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AdminHeading(
        'Tri thức AI',
        'Theo dõi nguồn dữ liệu phục vụ trợ lý ReStore.',
      ),
      AdminPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đồng bộ catalog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            AdminBadge(_syncStatus),
            const SizedBox(height: 12),
            const Text(
              'Catalog và tài liệu tại đây là dữ liệu minh họa. Kết nối đồng bộ, tải tệp và lập chỉ mục RAG sẽ được bổ sung ở bước API.',
            ),
            const SizedBox(height: 20),
            if (_syncing)
              const LinearProgressIndicator(
                semanticsLabel: 'Đang mô phỏng đồng bộ',
              )
            else
              AdminButton(
                'Thử luồng đồng bộ',
                icon: Icons.sync,
                onPressed: () async {
                  setState(() {
                    _syncing = true;
                    _syncStatus = 'Đang đồng bộ mẫu';
                  });
                  await Future<void>.delayed(const Duration(milliseconds: 800));
                  if (!mounted) return;
                  setState(() {
                    _syncing = false;
                    _syncStatus = 'Đã đồng bộ mẫu';
                  });
                  if (context.mounted) {
                    adminNotice(
                      context,
                      'Đã hoàn tất mô phỏng. Chưa gửi dữ liệu tới AI.',
                    );
                  }
                },
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      AdminButton(
        'Thêm tài liệu mẫu',
        icon: Icons.add,
        primary: true,
        onPressed: () async {
          final result = await adminDialog<List<String>>(
            context,
            title: 'Thông tin tài liệu mẫu',
            width: 520,
            child: const AdminTextForm(
              labels: ['Tên tài liệu', 'Mô tả nội dung'],
              initial: ['', ''],
            ),
          );
          if (result == null || !mounted) return;
          setState(
            () => _documents.add((name: result[0], description: result[1])),
          );
        },
      ),
      const SizedBox(height: 16),
      AdminTable(
        columns: const ['TÀI LIỆU', 'NỘI DUNG', ''],
        rows: [
          for (final doc in _documents)
            [
              Text(doc.name),
              SizedBox(width: 300, child: Text(doc.description)),
              TextButton(
                onPressed: () => adminDialog(
                  context,
                  title: 'Xóa tài liệu mẫu?',
                  width: 460,
                  child: Builder(
                    builder: (c) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name),
                        const SizedBox(height: 20),
                        AdminButton(
                          'Xóa khỏi bản mẫu',
                          danger: true,
                          onPressed: () {
                            setState(() => _documents.remove(doc));
                            Navigator.pop(c);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: const Text('Xóa'),
              ),
            ],
        ],
      ),
    ],
  );
}
