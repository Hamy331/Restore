import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../shared/widgets/listing_grid.dart';
import '../../listings/presentation/fixtures/figma_preview_listings.dart';

class SellerProfileView extends StatelessWidget {
  const SellerProfileView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Người bán'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'report') context.push('/report/user/minh-anh');
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'report', child: Text('Báo cáo người bán')),
          ],
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.infoBg,
                        child: Text(
                          'MA',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minh Anh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quận 1, TP. Hồ Chí Minh',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Thành viên từ 2022',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: _SellerMetric('★ 4,9', '48 đánh giá')),
                      Expanded(child: _SellerMetric('3', 'Tin đang bán')),
                      Expanded(child: _SellerMetric('12', 'Tin đã bán')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => context.push('/messages/minh-anh'),
                            child: const Text('Chat'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text('Xem tin đăng'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Tin đang bán',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('3 tin  ›'),
                ),
              ],
            ),
            ListingGrid(listings: figmaPreviewListings.take(4).toList()),
          ],
        ),
      ),
    ),
  );
}

class RatingsView extends StatelessWidget {
  const RatingsView({super.key});

  static const _reviews = [
    ('TN', 'Thảo Nguyễn', '20/09/2026', 5, 'Máy đúng mô tả, người bán trả lời nhanh. Hẹn xem hàng thuận tiện.'),
    ('QH', 'Quốc Hưng', '15/09/2026', 5, 'Trao đổi rõ ràng và rất đúng giờ.'),
    ('BT', 'Bảo Trâm', '02/09/2026', 4, 'Sản phẩm còn tốt, hình đăng sát thực tế.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Đánh giá người bán')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RatingSummary(),
            const SizedBox(height: 15),
            const Row(
              children: [
                Text(
                  'Nhận xét từ cộng đồng',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Spacer(),
                Text(
                  '48 nhận xét',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._reviews.map((review) => _ReviewCard(review: review)),
          ],
        ),
      ),
    ),
    bottomNavigationBar: _BottomAction(
      label: 'Viết đánh giá',
      onPressed: () => context.push('/seller/minh-anh/review'),
    ),
  );
}

class LeaveReviewView extends StatefulWidget {
  const LeaveReviewView({super.key});

  @override
  State<LeaveReviewView> createState() => _LeaveReviewViewState();
}

class _LeaveReviewViewState extends State<LeaveReviewView> {
  int _rating = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Viết đánh giá')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ResponsiveContent(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SellerSummary(),
            const SizedBox(height: 12),
            _WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn đánh giá người bán thế nào?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        tooltip: '${index + 1} sao',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 31,
                          height: 36,
                        ),
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_rating sao · ${_rating == 5 ? 'Rất tốt' : 'Đã chọn'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhận xét (không bắt buộc)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comment,
                    minLines: 4,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm trao đổi của bạn...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Đánh giá giúp cộng đồng hiểu về người bán. Hãy chia sẻ trải nghiệm trao đổi của bạn.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: _BottomAction(
      label: 'Gửi đánh giá',
      onPressed: () => _showPending(context, 'Đánh giá'),
    ),
  );
}

enum ReportTarget { listing, user }

class ReportView extends StatefulWidget {
  const ReportView({required this.target, super.key});

  final ReportTarget target;

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  String _reason = 'Thông tin sai lệch';
  bool _submitted = false;
  final _description = TextEditingController();

  static const _reasons = [
    'Nội dung không phù hợp',
    'Có dấu hiệu lừa đảo',
    'Sản phẩm bị cấm',
    'Thông tin sai lệch',
    'Spam',
    'Lý do khác',
  ];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Báo cáo')),
        body: ResponsiveContent(
          maxWidth: 560,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.successBg,
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Đã gửi báo cáo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cảm ơn bạn đã giúp ReStore an toàn hơn. Đội ngũ kiểm duyệt sẽ xem xét nội dung này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.target == ReportTarget.listing
              ? 'Báo cáo tin đăng'
              : 'Báo cáo người dùng',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ResponsiveContent(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.target == ReportTarget.listing
                  ? const _ReportedListing()
                  : const _SellerSummary(),
              const SizedBox(height: 12),
              const Text(
                'Lý do báo cáo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (value) {
                  if (value != null) setState(() => _reason = value);
                },
                child: Column(
                  children: _reasons.map(
                    (reason) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: RadioListTile<String>(
                        dense: true,
                        value: reason,
                        activeColor: AppColors.primary,
                        title: Text(reason, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ).toList(),
                ),
              ),
              const Text(
                'Mô tả thêm (không bắt buộc)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                minLines: 3,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Thêm thông tin để chúng tôi kiểm tra...',
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomAction(
        label: 'Gửi báo cáo',
        onPressed: () => setState(() => _submitted = true),
      ),
    );
  }
}

class _SellerMetric extends StatelessWidget {
  const _SellerMetric(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary();

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Row(
      children: [
        const SizedBox(
          width: 100,
          child: Column(
            children: [
              Text('4,9', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
              Text('★★★★★', style: TextStyle(color: AppColors.primary, fontSize: 18)),
              Text('48 đánh giá', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: const [
              _RatingBar(label: '5★', value: .88, count: '42'),
              _RatingBar(label: '4★', value: .12, count: '5'),
              _RatingBar(label: '3★', value: .04, count: '1'),
              _RatingBar(label: '2★', value: 0, count: '0'),
              _RatingBar(label: '1★', value: 0, count: '0'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.label, required this.value, required this.count});
  final String label;
  final double value;
  final String count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 24, child: Text(label, style: const TextStyle(fontSize: 10))),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 20, child: Text(count, textAlign: TextAlign.end, style: const TextStyle(fontSize: 9))),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final (String, String, String, int, String) review;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.infoBg,
              child: Text(review.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(review.$3, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text('★' * review.$4, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Text(review.$5, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _SellerSummary extends StatelessWidget {
  const _SellerSummary();
  @override
  Widget build(BuildContext context) => const _WhiteCard(
    child: Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.infoBg,
          child: Text('MA', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w700)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Minh Anh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 5),
              Text('Người bán · Quận 1, TP.HCM', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReportedListing extends StatelessWidget {
  const _ReportedListing();
  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset('assets/images/marketplace/listing-camera.png', width: 54, height: 54, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Máy ảnh Canon AE-1 + lens 50mm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Tin đăng của Minh Anh · Quận 1', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(9)),
    child: child,
  );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(height: 48, width: double.infinity, child: ElevatedButton(onPressed: onPressed, child: Text(label))),
      ),
    ),
  );
}

void _showPending(BuildContext context, String action) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action sẽ được kết nối API ở phase tính năng.')));
}
