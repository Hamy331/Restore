import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../shared/widgets/listing_grid.dart';
import '../../../chat/views/chat_conversation_view.dart';
import '../fixtures/figma_preview_listings.dart';

class ProductDetailView extends StatelessWidget {
  const ProductDetailView({
    required this.listingId,
    this.isPreview = false,
    super.key,
  });

  final String listingId;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final listing = figmaPreviewListings.firstWhere(
      (item) => item.id == listingId,
      orElse: () => figmaPreviewListings.first,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Text(isPreview ? 'Xem trước tin đăng' : 'Chi tiết tin đăng'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: AspectRatio(
                aspectRatio: 375 / 245,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(listing.imageAsset, fit: BoxFit.cover),
                    Positioned(
                      right: 16,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: .78),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Text(
                          '1 / 5',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              child: ResponsiveContent(
                maxWidth: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      'Máy ảnh film Canon AE-1 + lens 50mm',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2.450.000 đ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⌖ Quận 1, TP. Hồ Chí Minh  ·  Đăng 2 giờ trước',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 22),
                    const _InfoRow(
                      label: 'Tình trạng',
                      value: 'Đã qua sử dụng · Còn tốt',
                    ),
                    const Divider(height: 18),
                    const Text(
                      'Mô tả sản phẩm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Canon AE-1 hoạt động tốt, đo sáng chuẩn. Kèm lens FD 50mm f/1.8, dây đeo và bao da. Có thể xem máy trực tiếp tại Quận 1.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Divider(height: 22),
                    const _SellerRow(),
                    const Divider(height: 22),
                    Row(
                      children: [
                        const Text(
                          'Tin tương tự',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/search'),
                          child: const Text(
                            'Xem thêm  ›',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListingGrid(
                      listings: figmaPreviewListings.skip(1).take(2).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Align(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 728),
              child: Row(
                children: isPreview
                    ? _previewActions(context)
                    : _buyerActions(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buyerActions(BuildContext context) => [
    Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/messages/minh-anh'),
          icon: const Icon(Icons.chat_bubble_outline, size: 20),
          label: const Text('Chat'),
        ),
      ),
    ),
    const SizedBox(width: 10),
    SizedBox(
      width: 116,
      height: 48,
      child: OutlinedButton(
        onPressed: () => showMakeOfferSheet(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primaryDark,
        ),
        child: const Text('Trả giá'),
      ),
    ),
  ];

  List<Widget> _previewActions(BuildContext context) => [
    SizedBox(
      width: 116,
      height: 48,
      child: OutlinedButton(
        onPressed: () => context.go('/edit-listing'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
        ),
        child: const Text('Chỉnh sửa'),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng tin sẽ được nối API ở phase tính năng.'),
            ),
          ),
          child: const Text('Đăng tin'),
        ),
      ),
    ),
  ];
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class _SellerRow extends StatelessWidget {
  const _SellerRow();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.infoBg,
        child: Text(
          'MA',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minh Anh',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 3),
            Text(
              '★ 4,9  ·  48 đánh giá  ·  Phản hồi nhanh',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    ],
  );
}
