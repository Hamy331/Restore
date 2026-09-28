import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';

enum ManagedListingStatus { visible, pending, hidden, sold }

class ManageListingsView extends StatefulWidget {
  const ManageListingsView({super.key});

  @override
  State<ManageListingsView> createState() => _ManageListingsViewState();
}

class _ManageListingsViewState extends State<ManageListingsView> {
  ManagedListingStatus _status = ManagedListingStatus.visible;

  static const _activeItems = <_ManagedListing>[
    _ManagedListing(
      title: 'Máy ảnh Canon AE-1 + lens 50mm',
      price: '2.450.000 đ',
      image: 'assets/images/marketplace/listing-camera.png',
      meta: 'Đăng 2 giờ trước · 128 lượt xem',
    ),
    _ManagedListing(
      title: 'Đèn bàn đồng vintage',
      price: '590.000 đ',
      image: 'assets/images/marketplace/listing-lamp.png',
      meta: 'Đăng hôm qua · 76 lượt xem',
    ),
    _ManagedListing(
      title: 'Ghế gỗ sồi Bắc Âu',
      price: '1.200.000 đ',
      image: 'assets/images/marketplace/listing-chair.png',
      meta: 'Đăng 3 ngày trước · 204 lượt xem',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(_status);
    return SafeArea(
      child: Column(
        children: [
          ResponsiveContent(
            maxWidth: 760,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const Text(
                    'Quản lý tin',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    tooltip: 'Đăng tin mới',
                    onPressed: () => context.go('/create-listing'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 24),
                  ),
                ],
              ),
            ),
          ),
          ResponsiveContent(
            maxWidth: 760,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                scrollDirection: Axis.horizontal,
                children: ManagedListingStatus.values
                    .map(
                      (status) => TextButton(
                        onPressed: () => setState(() => _status = status),
                        style: TextButton.styleFrom(
                          foregroundColor: _status == status
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                        child: Text(
                          _label(status),
                          style: TextStyle(
                            fontSize: _status == status ? 12 : 11,
                            fontWeight: _status == status
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ResponsiveContent(
                  maxWidth: 760,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${items.length} ${_countLabel(_status)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ManagedListingCard(
                            item: item,
                            status: _status,
                            onEdit: () => context.go('/edit-listing'),
                            onMarkSold: () => _showMarkSold(context, item),
                            onAction: _showFoundationNotice,
                          ),
                        ),
                      ),
                      if (_status != ManagedListingStatus.visible)
                        _StatusNote(text: _statusNote(_status)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ManagedListing> _itemsFor(ManagedListingStatus status) {
    if (status == ManagedListingStatus.visible) return _activeItems;
    if (status == ManagedListingStatus.pending) {
      return const [
        _ManagedListing(
          title: 'Đèn bàn đồng vintage',
          price: '590.000 đ',
          image: 'assets/images/marketplace/listing-lamp.png',
          meta: 'Gửi 10 phút trước',
        ),
      ];
    }
    if (status == ManagedListingStatus.hidden) {
      return const [
        _ManagedListing(
          title: 'Ghế gỗ sồi Bắc Âu',
          price: '1.200.000 đ',
          image: 'assets/images/marketplace/listing-chair.png',
          meta: 'Đăng 3 ngày trước · 204 lượt xem',
        ),
      ];
    }
    return const [
      _ManagedListing(
        title: 'Máy ảnh Canon AE-1 + lens 50mm',
        price: '2.450.000 đ',
        image: 'assets/images/marketplace/listing-camera.png',
        meta: 'Đăng 2 giờ trước · 128 lượt xem',
      ),
    ];
  }

  String _label(ManagedListingStatus status) => switch (status) {
    ManagedListingStatus.visible => 'Đang hiển thị',
    ManagedListingStatus.pending => 'Chờ duyệt',
    ManagedListingStatus.hidden => 'Đã ẩn',
    ManagedListingStatus.sold => 'Đã bán',
  };

  String _countLabel(ManagedListingStatus status) => switch (status) {
    ManagedListingStatus.visible => 'tin đang hiển thị',
    ManagedListingStatus.pending => 'tin chờ duyệt',
    ManagedListingStatus.hidden => 'tin đã ẩn',
    ManagedListingStatus.sold => 'tin đã bán',
  };

  String _statusNote(ManagedListingStatus status) => switch (status) {
    ManagedListingStatus.pending =>
      'Tin đang được kiểm tra trước khi hiển thị.',
    ManagedListingStatus.hidden =>
      'Tin đang ẩn, người mua không thấy trong kết quả tìm kiếm.',
    ManagedListingStatus.sold =>
      'Tin đã bán không còn hiển thị trong kết quả tìm kiếm.',
    ManagedListingStatus.visible => '',
  };

  void _showFoundationNotice(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action sẽ được nối API ở phase tính năng.')),
    );
  }

  Future<void> _showMarkSold(BuildContext context, _ManagedListing item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Đánh dấu tin này là đã bán?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      item.image,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          item.price,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Tin sẽ không còn xuất hiện như một sản phẩm đang bán.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              const _StatusNote(
                text:
                    'Thao tác này không tạo đơn hàng hay giao dịch. ReStore không xử lý thanh toán.',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 104,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() => _status = ManagedListingStatus.sold);
                        },
                        child: const Text('Đánh dấu đã bán'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagedListingCard extends StatelessWidget {
  const _ManagedListingCard({
    required this.item,
    required this.status,
    required this.onEdit,
    required this.onMarkSold,
    required this.onAction,
  });

  final _ManagedListing item;
  final ManagedListingStatus status;
  final VoidCallback onEdit;
  final VoidCallback onMarkSold;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final actions = switch (status) {
      ManagedListingStatus.visible => <(String, VoidCallback)>[
        ('Chỉnh sửa', onEdit),
        ('Ẩn tin', () => onAction('Ẩn tin')),
        ('Đánh dấu đã bán', onMarkSold),
      ],
      ManagedListingStatus.pending => <(String, VoidCallback)>[
        ('Chỉnh sửa', onEdit),
        ('Xóa tin', () => onAction('Xóa tin')),
      ],
      ManagedListingStatus.hidden => <(String, VoidCallback)>[
        ('Hiện lại', () => onAction('Hiện lại')),
        ('Xóa tin', () => onAction('Xóa tin')),
      ],
      ManagedListingStatus.sold => <(String, VoidCallback)>[
        ('Xóa tin', () => onAction('Xóa tin')),
      ],
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  item.image,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      switch (status) {
                        ManagedListingStatus.visible => 'Đang hiển thị',
                        ManagedListingStatus.pending => 'Chờ duyệt',
                        ManagedListingStatus.hidden => 'Đã ẩn',
                        ManagedListingStatus.sold => 'Đã bán',
                      },
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: status == ManagedListingStatus.visible
                            ? const Color(0xFF32805A)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.meta,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: actions
                .map(
                  (action) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: action == actions.last ? 0 : 6,
                      ),
                      child: SizedBox(
                        height: 35,
                        child: OutlinedButton(
                          onPressed: action.$2,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            backgroundColor: action.$1 == 'Đánh dấu đã bán'
                                ? AppColors.primarySoft
                                : AppColors.surface,
                            side: BorderSide(
                              color: action.$1 == 'Đánh dấu đã bán'
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            action.$1,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: action.$1 == 'Đánh dấu đã bán'
                                  ? 10
                                  : 11,
                              color: action.$1 == 'Đánh dấu đã bán'
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.text});

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

class _ManagedListing {
  const _ManagedListing({
    required this.title,
    required this.price,
    required this.image,
    required this.meta,
  });

  final String title;
  final String price;
  final String image;
  final String meta;
}
