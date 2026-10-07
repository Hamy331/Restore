import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/listing_grid.dart';
import '../../../shared/widgets/feedback_view.dart';
import '../../listings/data/listing_repository.dart';
import '../../stores/data/store_repository.dart';

class HomeView extends StatefulWidget {
  const HomeView({this.repository, this.storeRepository, super.key});
  final ListingRepository? repository;
  final StoreRepository? storeRepository;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final ListingRepository _repository =
      widget.repository ?? ListingRepository();
  late Future<ListingPage> _listings = _repository.list();
  late Future<List<StoreCategory>> _categories =
      (widget.storeRepository ?? StoreRepository()).categories();

  void _reload() => setState(() => _listings = _repository.list());

  static const _categoryIcons = [
    Icons.category_outlined,
    Icons.chair_outlined,
    Icons.devices_outlined,
    Icons.checkroom,
    Icons.more_horiz,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _reload();
          try {
            await _listings;
          } catch (_) {
            // The FutureBuilder displays the retry state.
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ResponsiveContent(
                maxWidth: 840,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.my_location, size: 15),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Toàn quốc',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.notifications,
                          onPressed: () => context.push('/notifications'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                          icon: const Icon(Icons.notifications_none, size: 23),
                        ),
                        IconButton(
                          tooltip: l10n.restoreAi,
                          onPressed: () => context.push('/ai-assistant'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                          icon: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 21,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tin nhắn',
                          onPressed: () => context.go('/messages'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 21),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppSearchField(onTap: () => context.go('/search')),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 78,
                      padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đồ tốt đổi chủ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Đăng tin miễn phí, bán nhanh hôm nay',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<StoreCategory>>(
                      future: _categories,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return TextButton(
                            onPressed: () => setState(
                              () => _categories =
                                  (widget.storeRepository ?? StoreRepository())
                                      .categories(),
                            ),
                            child: const Text(
                              'Không tải được danh mục. Thử lại',
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        final categories = snapshot.data!.take(5).toList();
                        return Row(
                          children: [
                            for (var i = 0; i < categories.length; i++)
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.go(
                                    '/search?categoryId=${Uri.encodeComponent(categories[i].id)}',
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 45,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppColors.cream,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          _categoryIcons[i],
                                          size: 23,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        categories[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _SectionHeading(
                      title: 'Tin đăng mới',
                      action: 'Xem tất cả  ›',
                      onTap: () => context.go('/search'),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<ListingPage>(
                      future: _listings,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return FeedbackView(
                            icon: Icons.wifi_off_outlined,
                            title: 'Không tải được tin đăng',
                            message: 'Kiểm tra kết nối rồi thử lại.',
                            action: TextButton(
                              onPressed: _reload,
                              child: const Text('Thử lại'),
                            ),
                          );
                        }
                        final items = snapshot.data!.items;
                        if (items.isEmpty) {
                          return const FeedbackView(
                            icon: Icons.inventory_2_outlined,
                            title: 'Chưa có tin đăng',
                            message: 'Tin mới sẽ xuất hiện tại đây.',
                          );
                        }
                        return ListingGrid(listings: items);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(width: 8),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            action,
            maxLines: 1,
            style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
          ),
        ),
      ),
    ],
  );
}
