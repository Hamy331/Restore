import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/responsive/responsive_content.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/listing_grid.dart';
import '../../listings/presentation/fixtures/figma_preview_listings.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _categories = <(IconData, String)>[
    (Icons.phone_android, 'Điện thoại'),
    (Icons.two_wheeler, 'Xe cộ'),
    (Icons.chair_outlined, 'Nội thất'),
    (Icons.laptop_mac, 'Điện tử'),
    (Icons.checkroom, 'Thời trang'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: CustomScrollView(
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
                                'TP. Hồ Chí Minh',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, size: 17),
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
                        icon: const Icon(Icons.auto_awesome_outlined, size: 21),
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
                  Row(
                    children: _categories
                        .map(
                          (item) => Expanded(
                            child: InkWell(
                              onTap: () => context.go('/search'),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.cream,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(item.$1, size: 23),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeading(
                    title: 'Dành cho bạn',
                    action: 'Xem tất cả  ›',
                    onTap: () => context.go('/search'),
                  ),
                  const SizedBox(height: 10),
                  ListingGrid(listings: figmaPreviewListings),
                  const SizedBox(height: 22),
                  _SectionHeading(
                    title: 'Tin đăng mới',
                    action: 'Xem thêm  ›',
                    onTap: () => context.go('/search'),
                  ),
                  const SizedBox(height: 10),
                  ListingGrid(listings: figmaPreviewListings.reversed.toList()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
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
