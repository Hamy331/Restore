import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';

class CreateListingView extends StatefulWidget {
  const CreateListingView({this.editing = false, super.key});

  final bool editing;

  @override
  State<CreateListingView> createState() => _CreateListingViewState();
}

class _CreateListingViewState extends State<CreateListingView> {
  int _step = 1;
  bool _negotiable = true;
  String _condition = 'Đã qua sử dụng';
  String _contact = 'Chat';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          ResponsiveContent(
            maxWidth: 680,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    tooltip: _step == 1 ? 'Đóng' : 'Quay lại',
                    onPressed: () {
                      if (_step == 2) {
                        setState(() => _step = 1);
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 23),
                  ),
                  Text(
                    widget.editing ? 'Chỉnh sửa tin' : 'Đăng tin',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_step/2',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: Container(height: 4, color: AppColors.primary)),
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 4,
                  color: _step == 2 ? AppColors.primary : AppColors.border,
                ),
              ),
            ],
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ResponsiveContent(
                  maxWidth: 680,
                  child: _step == 1 ? _buildStepOne() : _buildStepTwo(),
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildStepOne() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Ảnh sản phẩm  ·  2/10',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 7),
      SizedBox(
        height: 78,
        child: Row(
          children: [
            _PhotoTile(order: 1),
            const SizedBox(width: 8),
            _PhotoTile(order: 2),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showPreviewNotice('Chọn ảnh'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primaryDark,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Ảnh đầu là ảnh bìa · Giữ và kéo để đổi thứ tự',
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 15),
      const _ListingField(
        label: 'Tên sản phẩm',
        value: 'Máy ảnh film Canon AE-1 + lens 50mm',
      ),
      const SizedBox(height: 15),
      const _ListingField(
        label: 'Danh mục',
        value: 'Điện tử  ›  Máy ảnh',
        readOnly: true,
      ),
      const SizedBox(height: 15),
      const Text(
        'Tình trạng',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 7),
      Wrap(
        spacing: 8,
        children: ['Mới', 'Đã qua sử dụng']
            .map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: _condition == value,
                showCheckmark: false,
                selectedColor: AppColors.primarySoft,
                side: BorderSide(
                  color: _condition == value
                      ? AppColors.primary
                      : AppColors.border,
                ),
                onSelected: (_) => setState(() => _condition = value),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
      const _WarmNote(
        text: 'Mẹo: ảnh rõ, nhiều góc chụp giúp tin đăng đáng tin hơn.',
      ),
    ],
  );

  Widget _buildStepTwo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _ListingField(
        label: 'Giá bán',
        value: '2.450.000 đ',
        helper: 'Nhập giá bằng VND',
      ),
      const SizedBox(height: 15),
      Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Text(
              'Có thể thương lượng',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Switch(
              value: _negotiable,
              activeTrackColor: AppColors.primary,
              onChanged: (value) => setState(() => _negotiable = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      const _ListingField(
        label: 'Mô tả',
        value:
            'Canon AE-1 hoạt động tốt, đo sáng chuẩn. Kèm lens FD 50mm f/1.8, dây đeo và bao da.',
        lines: 4,
      ),
      const SizedBox(height: 15),
      const _ListingField(label: 'Địa điểm', value: 'Quận 1, TP. Hồ Chí Minh'),
      const SizedBox(height: 15),
      const Text(
        'Ưu tiên liên hệ',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 7),
      Wrap(
        spacing: 8,
        children: ['Chat', 'Điện thoại']
            .map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: _contact == value,
                showCheckmark: false,
                selectedColor: AppColors.primarySoft,
                side: BorderSide(
                  color: _contact == value
                      ? AppColors.primary
                      : AppColors.border,
                ),
                onSelected: (_) => setState(() => _contact = value),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 26),
      const Text(
        'Người mua và người bán tự thỏa thuận giao nhận, thanh toán.',
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 648),
          child: Row(
            children: [
              if (_step == 2) ...[
                SizedBox(
                  width: 116,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.push('/create-listing/preview'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primaryDark,
                    ),
                    child: const Text('Xem trước'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_step == 1) {
                        setState(() => _step = 2);
                      } else {
                        _showPreviewNotice(
                          widget.editing ? 'Lưu thay đổi' : 'Đăng tin',
                        );
                      }
                    },
                    child: Text(
                      _step == 1
                          ? 'Tiếp tục'
                          : widget.editing
                          ? 'Lưu thay đổi'
                          : 'Đăng tin',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _showPreviewNotice(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action sẽ được nối API ở phase tính năng.')),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/marketplace/listing-camera.png',
          width: 78,
          height: 78,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        right: 4,
        top: 4,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 15),
        ),
      ),
      Positioned(
        left: 4,
        bottom: 4,
        child: Container(
          width: 22,
          height: 19,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '$order',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  );
}

class _ListingField extends StatelessWidget {
  const _ListingField({
    required this.label,
    required this.value,
    this.helper,
    this.lines = 1,
    this.readOnly = false,
  });

  final String label;
  final String value;
  final String? helper;
  final int lines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value,
        readOnly: readOnly,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(
          suffixIcon: readOnly
              ? const Icon(Icons.chevron_right, size: 20)
              : null,
        ),
      ),
      if (helper != null) ...[
        const SizedBox(height: 6),
        Text(
          helper!,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ],
  );
}

class _WarmNote extends StatelessWidget {
  const _WarmNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}
