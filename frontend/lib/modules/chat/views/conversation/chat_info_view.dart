import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import '../../models/chat_models.dart';
import '../../repositories/chat_repository.dart';
import '../../widgets/chat_attachment.dart';
import '../../widgets/chat_product_preview.dart';

typedef DiscussedProduct = ({String contextId, ChatProduct product});
typedef ChatInfoResult = ({bool hidden, DiscussedProduct? selection});

class ChatInfoView extends StatefulWidget {
  const ChatInfoView({super.key, required this.chat});
  final ChatConversation chat;
  @override
  State<ChatInfoView> createState() => _ChatInfoViewState();
}

class _ChatInfoViewState extends State<ChatInfoView> {
  final api = ApiChatRepository();
  late final String id = widget.chat.id;
  late bool blocked = widget.chat.blockedByMe;
  late Future<List<DiscussedProduct>> products = api.discussed(id);
  late Future<List<ChatMessage>> media = api.getMessages(id, mediaOnly: true);
  bool busy = false;

  Future<void> change({bool hide = false}) async {
    final label = hide
        ? 'Ẩn hội thoại'
        : blocked
        ? 'Bỏ chặn người dùng'
        : 'Chặn người dùng';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(
          hide
              ? 'Hội thoại sẽ ẩn khỏi hộp thư của bạn và hiện lại khi có tin mới.'
              : blocked
              ? 'Cho phép hai bên tiếp tục gửi tin nhắn?'
              : 'Hai bên sẽ không thể nhắn tin cho nhau cho đến khi bạn bỏ chặn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || busy) return;
    setState(() => busy = true);
    try {
      await api.preferences(
        id,
        hidden: hide ? true : null,
        blocked: hide ? null : !blocked,
      );
      if (!mounted) return;
      if (hide) {
        Navigator.pop<ChatInfoResult>(context, (hidden: true, selection: null));
      } else {
        setState(() => blocked = !blocked);
      }
    } catch (_) {
      if (mounted) _notice('Không lưu được thay đổi. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> report() async {
    final detail = await showDialog<String>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );
    if (!mounted || detail == null) return;
    setState(() => busy = true);
    try {
      await ApiClient().dio.post(
        '/content/reports',
        data: {
          'targetType': 'USER',
          'targetId': widget.chat.otherUser.id,
          'reason': 'Báo xấu trong hội thoại',
          'evidence': 'Hội thoại $id\n$detail',
        },
      );
      if (mounted) _notice('Đã gửi báo cáo đến ReStore.');
    } catch (_) {
      if (mounted) {
        _notice(
          'Không gửi được báo cáo. Hãy kiểm tra kết nối hoặc báo cáo đang chờ xử lý.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget productRow(DiscussedProduct row, {required void Function() reply}) =>
      ListTile(
        title: ChatProductPreview(
          product: row.product,
          onTap: () => context.push('/listings/${row.product.id}'),
        ),
        trailing: TextButton(onPressed: reply, child: const Text('Nhắn')),
      );
  void select(DiscussedProduct row) =>
      Navigator.pop<ChatInfoResult>(context, (hidden: false, selection: row));
  Future<void> showProducts(List<DiscussedProduct> rows) async {
    final selected = await Navigator.push<DiscussedProduct>(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Tin đang trao đổi')),
          body: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) =>
                productRow(rows[i], reply: () => Navigator.pop(ctx, rows[i])),
          ),
        ),
      ),
    );
    if (mounted && selected != null) select(selected);
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.chat.otherUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundImage: person.avatarUrl == null
                  ? null
                  : appImageProvider(person.avatarUrl!),
              child: person.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            person.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Center(
            child: TextButton(
              onPressed: () => context.push('/users/${person.id}'),
              child: const Text('Xem trang'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Hình và video'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => _Gallery(id: id)),
            ),
          ),
          FutureBuilder<List<ChatMessage>>(
            future: media,
            builder: (_, snap) {
              if (snap.hasError) {
                return TextButton(
                  onPressed: () => setState(
                    () => media = api.getMessages(id, mediaOnly: true),
                  ),
                  child: const Text('Tải lại hình và video'),
                );
              }
              if (!snap.hasData) return const LinearProgressIndicator();
              if (snap.data!.isEmpty) {
                return const ListTile(
                  subtitle: Text('Chưa có hình hoặc video trong hội thoại.'),
                );
              }
              return Wrap(
                spacing: 8,
                children: [
                  for (final m in snap.data!.reversed.take(2))
                    SizedBox(
                      width: 122,
                      child: ChatAttachment(
                        key: ValueKey(m.id),
                        thread: id,
                        message: m,
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          FutureBuilder<List<DiscussedProduct>>(
            future: products,
            builder: (_, snap) {
              final rows = snap.data ?? [];
              return Column(
                children: [
                  ListTile(
                    title: const Text('Tin đang trao đổi'),
                    trailing: rows.isEmpty
                        ? null
                        : const Icon(Icons.chevron_right),
                    onTap: rows.isEmpty ? null : () => showProducts(rows),
                  ),
                  if (snap.hasError)
                    TextButton(
                      onPressed: () =>
                          setState(() => products = api.discussed(id)),
                      child: const Text('Tải lại tin'),
                    ),
                  if (snap.connectionState == ConnectionState.waiting)
                    const LinearProgressIndicator(),
                  if (snap.hasData && rows.isEmpty)
                    const ListTile(
                      subtitle: Text('Chưa trao đổi về sản phẩm nào.'),
                    ),
                  for (final row in rows.take(2))
                    productRow(row, reply: () => select(row)),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Báo xấu'),
            onTap: busy ? null : report,
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: Text(blocked ? 'Bỏ chặn người dùng' : 'Chặn người dùng'),
            onTap: busy ? null : () => change(),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Ẩn hội thoại'),
            onTap: busy ? null : () => change(hide: true),
          ),
        ],
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String details = '';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Báo xấu người dùng'),
    content: TextField(
      autofocus: true,
      maxLength: 2000,
      maxLines: 4,
      decoration: const InputDecoration(labelText: 'Mô tả sự việc'),
      onChanged: (v) => setState(() => details = v.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: details.length < 5
            ? null
            : () => Navigator.pop(context, details),
        child: const Text('Gửi báo cáo'),
      ),
    ],
  );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.id});
  final String id;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final items = <ChatMessage>[];
  bool more = true, loading = false, failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final page = await ApiChatRepository().getMessages(
        widget.id,
        before: items.lastOrNull?.sequence,
        mediaOnly: true,
      );
      if (mounted) {
        setState(() {
          items.addAll(page.reversed);
          more = page.length == 30;
        });
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hình và video')),
    body: GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length + (more || items.isEmpty ? 1 : 0),
      itemBuilder: (_, i) => i < items.length
          ? ChatAttachment(
              key: ValueKey(items[i].id),
              thread: widget.id,
              message: items[i],
            )
          : Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : more
                  ? TextButton(
                      onPressed: load,
                      child: Text(failed ? 'Thử lại' : 'Xem thêm'),
                    )
                  : const Text('Chưa có hình hoặc video.'),
            ),
    ),
  );
}
