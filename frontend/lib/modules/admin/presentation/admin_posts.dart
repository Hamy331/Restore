import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_preview_data.dart';
import 'admin_widgets.dart';

typedef AdminPost = ({
  String id,
  String title,
  String category,
  String content,
  String cover,
  String status,
});

class AdminPostsView extends StatefulWidget {
  const AdminPostsView({super.key});
  @override
  State<AdminPostsView> createState() => _AdminPostsViewState();
}

class _AdminPostsViewState extends State<AdminPostsView> {
  String _query = '', _status = 'Tất cả';
  final _posts = <AdminPost>[
    (
      id: 'BV-001',
      title: '5 điều cần kiểm tra khi mua máy ảnh cũ',
      category: 'Hướng dẫn mua bán',
      content:
          'Kiểm tra ngoại hình, ống kính và các nút điều khiển.\n\nHẹn xem sản phẩm tại địa điểm công cộng. Thử chụp và kiểm tra ảnh trước khi thỏa thuận giao dịch.',
      cover: 'camera',
      status: 'Đã xuất bản',
    ),
    (
      id: 'BV-002',
      title: 'Trao đồ cũ, nhận niềm vui mới',
      category: 'Cộng đồng',
      content:
          'Mỗi món đồ đều có thể bắt đầu một hành trình mới. Đăng ảnh rõ ràng, mô tả đúng tình trạng và trao đổi trực tiếp với người quan tâm.',
      cover: 'chair',
      status: 'Bản nháp',
    ),
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AdminHeading(
        'Bài viết',
        'Chia sẻ hướng dẫn, mẹo giao dịch và thông tin từ ReStore.',
        action: AdminButton(
          'Viết bài mới',
          primary: true,
          icon: Icons.edit_outlined,
          onPressed: () => _edit(),
        ),
      ),
      Wrap(
        spacing: 12,
        runSpacing: 16,
        children: [
          AdminSearch(
            hint: 'Tìm tiêu đề bài viết',
            onChanged: (v) => setState(() => _query = v),
          ),
          AdminSelect(
            value: _status,
            values: const [
              'Tất cả',
              'Bản nháp',
              'Đã xuất bản',
              'Đang ẩn',
              'Lưu trữ',
            ],
            label: 'Trạng thái',
            onChanged: (v) => setState(() => _status = v),
          ),
        ],
      ),
      const SizedBox(height: 20),
      AdminTable(
        columns: const ['BÀI VIẾT', 'CHUYÊN MỤC', 'TRẠNG THÁI', ''],
        rows: [
          for (final x in _posts.where(
            (x) =>
                x.title.toLowerCase().contains(_query.toLowerCase()) &&
                (_status == 'Tất cả' || x.status == _status),
          ))
            [
              SizedBox(
                width: 300,
                child: Text(
                  x.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(x.category),
              AdminBadge(x.status),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _edit(x),
                    child: const Text('Chỉnh sửa'),
                  ),
                  TextButton(
                    onPressed: () => previewAdminPost(context, x),
                    child: const Text('Xem trước'),
                  ),
                ],
              ),
            ],
        ],
      ),
    ],
  );
  Future<void> _edit([AdminPost? post]) async {
    final updated = await adminDialog<AdminPost>(
      context,
      title: post == null ? 'Bài viết mới' : 'Chỉnh sửa bài viết',
      width: 900,
      child: _PostEditor(post: post),
    );
    if (updated == null || !mounted) return;
    setState(() {
      final index = _posts.indexWhere((x) => x.id == updated.id);
      if (index < 0) {
        _posts.add(updated);
      } else {
        _posts[index] = updated;
      }
    });
    context.read<AdminPreviewCubit>().record(
      updated.id,
      'Lưu bài viết · ${updated.status}',
      updated.title,
    );
    adminNotice(context);
  }
}

void previewAdminPost(BuildContext context, AdminPost post) => adminDialog(
  context,
  title: 'Xem trước bài viết',
  width: 720,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/marketplace/listing-${post.cover}.png',
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: 20),
      Text(post.category, style: const TextStyle(color: AppColors.primaryDark)),
      const SizedBox(height: 8),
      Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 20),
      Text(post.content),
    ],
  ),
);

class _PostEditor extends StatefulWidget {
  const _PostEditor({this.post});
  final AdminPost? post;
  @override
  State<_PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<_PostEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.post?.title ?? '');
  late final _content = TextEditingController(text: widget.post?.content ?? '');
  late String _category = widget.post?.category ?? 'Hướng dẫn mua bán';
  late String _cover = widget.post?.cover ?? 'camera';
  late String _status = widget.post?.status ?? 'Bản nháp';
  bool _dirty = false, _closing = false;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  AdminPost _post() => (
    id: widget.post?.id ?? 'BV-${DateTime.now().microsecondsSinceEpoch}',
    title: _title.text.trim(),
    category: _category,
    content: _content.text.trim(),
    cover: _cover,
    status: _status,
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty || _closing,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Bỏ thay đổi chưa lưu?'),
          content: const Text('Nội dung vừa chỉnh sửa sẽ bị mất.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Tiếp tục viết'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        ),
      );
      if (discard == true && context.mounted) {
        setState(() => _closing = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: Form(
      key: _form,
      onChanged: () {
        if (!_dirty) setState(() => _dirty = true);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _title,
            maxLength: 160,
            decoration: const InputDecoration(labelText: 'Tiêu đề bài viết'),
            validator: _required,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              AdminSelect(
                value: _category,
                values: const [
                  'Hướng dẫn mua bán',
                  'An toàn giao dịch',
                  'Cộng đồng',
                  'Thông báo',
                ],
                label: 'Chuyên mục',
                onChanged: (v) => setState(() {
                  _category = v;
                  _dirty = true;
                }),
              ),
              AdminSelect(
                value: _status,
                values: const ['Bản nháp', 'Đã xuất bản', 'Đang ẩn', 'Lưu trữ'],
                label: 'Trạng thái sau lưu',
                onChanged: (v) => setState(() {
                  _status = v;
                  _dirty = true;
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Ảnh bìa mẫu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (image, label) in [
                ('camera', 'Máy ảnh'),
                ('lamp', 'Đèn bàn'),
                ('chair', 'Ghế gỗ'),
              ])
                Semantics(
                  label: 'Chọn ảnh bìa $label',
                  selected: _cover == image,
                  child: InkWell(
                    onTap: () => setState(() {
                      _cover = image;
                      _dirty = true;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _cover == image
                              ? AppColors.primaryDark
                              : AppColors.border,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/images/marketplace/listing-$image.png',
                        width: 88,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _content,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(labelText: 'Nội dung'),
            validator: _required,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              AdminButton(
                'Xem trước',
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    previewAdminPost(context, _post());
                  }
                },
              ),
              AdminButton(
                'Lưu bài viết mẫu',
                primary: true,
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  setState(() => _closing = true);
                  final post = _post();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) Navigator.pop(context, post);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Vui lòng nhập nội dung.' : null;
}
