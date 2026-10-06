import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../shared/widgets/feedback_view.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/domain/entities/listing_preview.dart';
import '../data/store_repository.dart';

class PromotionView extends StatefulWidget {
  const PromotionView({
    this.initialListingId,
    this.storeRepository,
    this.listingRepository,
    super.key,
  });
  final String? initialListingId;
  final StoreRepository? storeRepository;
  final ListingRepository? listingRepository;

  @override
  State<PromotionView> createState() => _PromotionViewState();
}

class _PromotionViewState extends State<PromotionView> {
  late final StoreRepository _stores =
      widget.storeRepository ?? StoreRepository();
  late final ListingRepository _listings =
      widget.listingRepository ?? ListingRepository();
  late Future<(StoreSummary, List<PromotionPackage>, List<ListingPreview>)>
  _data = _load();
  String? _listingId;
  String? _packageId;
  bool _submitting = false;

  Future<(StoreSummary, List<PromotionPackage>, List<ListingPreview>)>
  _load() async => (
    await _stores.me(),
    await _stores.promotionPackages(),
    await _listings.mineAvailable(),
  );

  Future<void> _submit({required bool included}) async {
    if (_listingId == null || _packageId == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      if (included) {
        await _stores.redeem(listingId: _listingId!, packageId: _packageId!);
      } else {
        await _stores.orderPromotion(
          listingId: _listingId!,
          packageId: _packageId!,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            included
                ? 'Đã kích hoạt quảng cáo bằng lượt kèm gói.'
                : 'Đã gửi đơn. Quảng cáo sẽ kích hoạt sau khi admin xác nhận thanh toán.',
          ),
        ),
      );
      setState(() => _data = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không xử lý được quảng cáo. Kiểm tra điều kiện tin, hạn mức hoặc đơn đang chờ.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Quảng cáo tin đăng')),
    body: FutureBuilder<(StoreSummary, List<PromotionPackage>, List<ListingPreview>)>(
      future: _data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return FeedbackView(
              icon: Icons.wifi_off_outlined,
              title: 'Không tải được quảng cáo',
              message: 'Kiểm tra kết nối rồi thử lại.',
              action: TextButton(
                onPressed: () => setState(() => _data = _load()),
                child: const Text('Thử lại'),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final (summary, packages, listings) = snapshot.data!;
        final listingId =
            _listingId ??
            (listings.any((item) => item.id == widget.initialListingId)
                ? widget.initialListingId
                : null);
        final listing = listings
            .where((item) => item.id == listingId)
            .firstOrNull;
        final selectedPackage = packages
            .where((item) => item.id == _packageId)
            .firstOrNull;
        final canUseIncluded =
            listing != null &&
            selectedPackage != null &&
            summary.category?.id == listing.categoryId &&
            summary.remainingPromotions > 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveContent(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đẩy Tin đưa tin lên đầu theo lượt trong 1, 3 hoặc 7 ngày. Tin Ưu Tiên giữ vị trí ưu tiên suốt thời hạn.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: listingId,
                  decoration: const InputDecoration(
                    labelText: 'Tin đang hiển thị của bạn',
                  ),
                  items: [
                    for (final item in listings)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.title} · ${item.categoryName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _listingId = value),
                ),
                if (listings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Bạn cần có tin đang hiển thị để quảng cáo.'),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _packageId,
                  decoration: const InputDecoration(
                    labelText: 'Loại quảng cáo và thời hạn',
                  ),
                  items: [
                    for (final item in packages)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.kind == 'BUMP' ? 'Đẩy Tin' : 'Tin Ưu Tiên'} · ${item.durationDays} ngày · ${NumberFormat.decimalPattern('vi').format(num.parse(item.price))} đ',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _packageId = value),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lượt kèm gói còn lại: ${summary.remainingPromotions}. Chỉ dùng cho danh mục ${summary.category?.name ?? 'chưa chọn'}.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: canUseIncluded && !_submitting
                          ? () => _submit(included: true)
                          : null,
                      child: const Text('Dùng lượt kèm gói'),
                    ),
                    OutlinedButton(
                      onPressed:
                          listing != null &&
                              selectedPackage != null &&
                              !_submitting
                          ? () => _submit(included: false)
                          : null,
                      child: const Text('Tạo đơn mua riêng'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đơn mua riêng cần admin xác nhận thanh toán trước khi kích hoạt.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
