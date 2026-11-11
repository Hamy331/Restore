import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_environment.dart';
import '../../../shared/widgets/app_local_image.dart';

Future<void> reportListing(BuildContext context, String listingId) async {
  final reason = TextEditingController(), evidence = TextEditingController();
  bool busy = false;
  String error = '';
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Báo cáo tin đăng'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reason,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Lý do (5–300 ký tự)',
                  ),
                ),
                TextField(
                  controller: evidence,
                  enabled: !busy,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả bằng chứng (5–4000 ký tự)',
                  ),
                ),
                if (error.isNotEmpty) Text(error),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialog),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      update(() => busy = true);
                      try {
                        await ApiClient().dio.post<void>(
                          '/content/reports',
                          data: {
                            'targetType': 'LISTING',
                            'targetId': listingId,
                            'reason': reason.text,
                            'evidence': evidence.text,
                          },
                        );
                        if (dialog.mounted) Navigator.pop(dialog);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã gửi báo cáo tới quản trị viên.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialog.mounted) {
                          update(() => error = _apiMessage(e));
                        }
                      } finally {
                        if (dialog.mounted) update(() => busy = false);
                      }
                    },
              child: const Text('Gửi báo cáo'),
            ),
          ],
        ),
      ),
    );
  } finally {
    reason.dispose();
    evidence.dispose();
  }
}

String _apiMessage(Object e) => e is DioException && e.response?.data is Map
    ? '${e.response!.data['error']}'
    : 'Không kết nối được máy chủ.';

class CommunityContentView extends StatefulWidget {
  const CommunityContentView({this.blog = false, super.key});
  final bool blog;
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
      widget.blog ? '/content/posts' : '/content/tickets',
    );
    final data = response.data!['data'];
    return widget.blog ? List.from(data['items']) : List.from(data);
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

  Future<void> _post(String slug) async {
    try {
      final data =
          (await ApiClient().dio.get<Map<String, dynamic>>(
                '/content/posts/${Uri.encodeComponent(slug)}',
              )).data!['data']
              as Map;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialog) => Dialog(
          child: SizedBox(
            width: 750,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (data['coverUrl'] != null)
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: AppLocalImage(
                        path:
                            '${Uri.parse(AppEnvironment.apiBaseUrl).origin}${data['coverUrl']}',
                      ),
                    ),
                  const SizedBox(height: 16),
                  SelectableText(data['content']),
                  const Divider(),
                  const Text('Sản phẩm liên quan / quảng cáo'),
                  for (final listing in data['listings'] as List)
                    ListTile(
                      title: Text(listing['title']),
                      subtitle: Text('${listing['price']} đ'),
                      onTap: () {
                        Navigator.pop(dialog);
                        context.push('/listings/${listing['id']}');
                      },
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_apiMessage(e))));
      }
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
      title: Text(widget.blog ? 'Blog ReStore' : 'Hỗ trợ & câu hỏi thường gặp'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!widget.blog) ...[
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
                      title: Text(widget.blog ? row['title'] : row['subject']),
                      subtitle: Text(
                        widget.blog ? row['category'] : row['status'],
                      ),
                      onTap: () => widget.blog
                          ? _post(row['slug'])
                          : _ticket(row as Map),
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
