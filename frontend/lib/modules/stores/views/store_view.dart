import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../shared/widgets/feedback_view.dart';
import '../data/store_repository.dart';

class StoreView extends StatefulWidget {
  const StoreView({this.repository, super.key});
  final StoreRepository? repository;

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  late final StoreRepository _repository =
      widget.repository ?? StoreRepository();
  late Future<(StoreSummary, List<StorePackage>, List<StoreCategory>)> _data =
      _load();
  String? _categoryId;
  bool _submitting = false;

  Future<(StoreSummary, List<StorePackage>, List<StoreCategory>)>
  _load() async => (
    await _repository.me(),
    await _repository.packages(),
    await _repository.categories(),
  );

  void _reload() => setState(() => _data = _load());

  Future<void> _order(StorePackage item) async {
    if (_categoryId == null || _submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn danh mục trọng tâm của cửa hàng.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repository.orderStorePackage(
        packageId: item.id,
        categoryId: _categoryId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi đơn. Gói sẽ kích hoạt sau khi admin xác nhận thanh toán.',
          ),
        ),
      );
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không tạo được đơn. Kiểm tra kết nối hoặc đơn đang chờ.',
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
    appBar: AppBar(title: const Text('Gói cửa hàng')),
    body: FutureBuilder<(StoreSummary, List<StorePackage>, List<StoreCategory>)>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return FeedbackView(
            icon: Icons.wifi_off_outlined,
            title: 'Không tải được gói cửa hàng',
            message: 'Kiểm tra kết nối rồi thử lại.',
            action: TextButton(
              onPressed: _reload,
              child: const Text('Thử lại'),
            ),
          );
        }
        final (summary, packages, categories) = snapshot.data!;
        _categoryId ??= summary.category?.id;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveContent(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang dùng: ${summary.package.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (summary.endsAt != null)
                  Text(
                    'Hết hạn: ${summary.endsAt!.day}/${summary.endsAt!.month}/${summary.endsAt!.year}',
                  ),
                if (summary.category != null)
                  Text('Danh mục trọng tâm: ${summary.category!.name}'),
                if (summary.pendingOrderId != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Có đơn gói cửa hàng đang chờ admin xác nhận.',
                      style: TextStyle(color: AppColors.primaryDark),
                    ),
                  ),
                const SizedBox(height: 12),
                _UsageBar(
                  'Tin hôm nay',
                  summary.today,
                  summary.package.dailyListingLimit,
                ),
                _UsageBar(
                  'Tin đang hoạt động',
                  summary.active,
                  summary.package.activeListingLimit,
                ),
                _UsageBar(
                  'Quảng cáo tháng này',
                  summary.promotionsThisMonth,
                  summary.package.monthlyPromotionQuota,
                ),
                const SizedBox(height: 20),
                Text(
                  'Quyền lợi gói',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục trọng tâm khi mua gói',
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ưu tiên hiển thị và lượt quảng cáo kèm gói chỉ áp dụng trong danh mục đã chọn. Hạn mức đăng tin áp dụng toàn ứng dụng.',
                ),
                const SizedBox(height: 8),
                for (final item in packages)
                  Card(
                    color: item.tier == summary.package.tier
                        ? AppColors.primarySoft
                        : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${NumberFormat.decimalPattern('vi').format(num.parse(item.monthlyPrice))} đ / 30 ngày',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.dailyListingLimit} tin/ngày · ${item.activeListingLimit} tin đang hoạt động',
                          ),
                          Text(
                            '${item.monthlyPromotionQuota} lượt quảng cáo/tháng · ưu tiên ${item.priorityLevel}',
                          ),
                          if (item.tier == summary.package.tier)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Gói hiện tại',
                                style: TextStyle(color: AppColors.primaryDark),
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _submitting || summary.pendingOrderId != null
                                  ? null
                                  : () => _order(item),
                              child: Text(
                                item.tier == summary.package.tier
                                    ? 'Gia hạn'
                                    : 'Đăng ký',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/promotions'),
                  icon: const Icon(Icons.campaign_outlined),
                  label: Text(
                    'Dùng lượt quảng cáo còn lại (${summary.remainingPromotions})',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _UsageBar extends StatelessWidget {
  const _UsageBar(this.label, this.used, this.limit);
  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $used/$limit'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: limit == 0 ? 0 : (used / limit).clamp(0, 1),
          minHeight: 7,
          color: AppColors.primary,
          backgroundColor: AppColors.border,
        ),
      ],
    ),
  );
}
