import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

export 'report_listing_sheet.dart' show reportListing;

String _apiMessage(Object e) => e is DioException && e.response?.data is Map
    ? '${e.response!.data['error']}'
    : 'Không kết nối được máy chủ.';

class CommunityContentView extends StatefulWidget {
  const CommunityContentView({super.key});
  @override
  State<CommunityContentView> createState() => _CommunityContentViewState();
}

class _CommunityContentViewState extends State<CommunityContentView> {
  late Future<List<dynamic>> _items = _load();
  final _question = TextEditingController();
  List<dynamic> _answers = [];
  String _error = '';
  bool _searching = false;
  Future<List<dynamic>> _load() async {
    final response = await ApiClient().dio.get<Map<String, dynamic>>(
      '/content/tickets',
    );
    final data = response.data!['data'];
    return List.from(data);
  }

  void _refresh() => setState(() => _items = _load());
  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _ticket([Map? row]) async {
    final subject = TextEditingController(), content = TextEditingController();
    String error = '';
    bool busy = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text(row == null ? 'Yêu cầu hỗ trợ' : row['subject']),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (row != null)
                      for (final message in row['messages'] as List)
                        ListTile(
                          title: Text(
                            message['isAdmin'] == true
                                ? 'Quản trị viên'
                                : 'Bạn',
                          ),
                          subtitle: Text(message['content']),
                        ),
                    if (row == null)
                      TextField(
                        controller: subject,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề (5–160 ký tự)',
                        ),
                      ),
                    if (row == null || row['status'] == 'OPEN')
                      TextField(
                        controller: content,
                        enabled: !busy,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                        ),
                      ),
                    if (error.isNotEmpty) Text(error),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialog),
                child: const Text('Đóng'),
              ),
              if (row == null || row['status'] == 'OPEN')
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          update(() => busy = true);
                          try {
                            await ApiClient().dio.post<void>(
                              row == null
                                  ? '/content/tickets'
                                  : '/content/tickets/${row['id']}/reply',
                              data: {
                                if (row == null) 'subject': subject.text,
                                'content': content.text,
                              },
                            );
                            if (dialog.mounted) Navigator.pop(dialog);
                            if (mounted) _refresh();
                          } catch (e) {
                            if (dialog.mounted) {
                              update(() => error = _apiMessage(e));
                            }
                          } finally {
                            if (dialog.mounted) update(() => busy = false);
                          }
                        },
                  child: const Text('Gửi'),
                ),
            ],
          ),
        ),
      );
    } finally {
      subject.dispose();
      content.dispose();
    }
  }

  Future<void> _search() async {
    if (_searching) return;
    setState(() {
      _searching = true;
      _error = '';
    });
    try {
      final data = (await ApiClient().dio.get<Map<String, dynamic>>(
        '/content/knowledge/search',
        queryParameters: {'q': _question.text},
      )).data!['data'];
      if (mounted) setState(() => _answers = List.from(data['documents']));
    } catch (e) {
      if (mounted) setState(() => _error = _apiMessage(e));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hỗ trợ & câu hỏi thường gặp'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...[
          TextField(
            controller: _question,
            decoration: InputDecoration(
              labelText: 'Tìm câu trả lời từ tài liệu hệ thống',
              suffixIcon: IconButton(
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          if (_searching) const LinearProgressIndicator(),
          if (_error.isNotEmpty) Text(_error),
          for (final answer in _answers)
            ExpansionTile(
              title: Text(answer['title']),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(answer['content']),
                ),
              ],
            ),
          FilledButton(
            onPressed: () => _ticket(),
            child: const Text('Gửi yêu cầu hỗ trợ'),
          ),
          const Divider(),
        ],
        FutureBuilder<List<dynamic>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TextButton(
                onPressed: _refresh,
                child: const Text(
                  'Không tải được dữ liệu. Đăng nhập hoặc thử lại.',
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: AppLoadingIndicator());
            }
            return Column(
              children: [
                if (snapshot.data!.isEmpty)
                  const ListTile(title: Text('Chưa có dữ liệu.')),
                for (final row in snapshot.data!)
                  Card(
                    child: ListTile(
                      title: Text(row['subject']),
                      subtitle: Text(
                        row['status'],
                      ),
                      onTap: () => _ticket(row as Map),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
