import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ui/responsive/responsive_content.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/listing_grid.dart';
import '../fixtures/figma_preview_listings.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  String _selected = 'Gần tôi';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const filters = ['Gần tôi', 'Giá', 'Tình trạng', 'Có ảnh'];
    return SafeArea(
      child: ResponsiveContent(
        maxWidth: 840,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  AppSearchField(
                    controller: _controller,
                    hintText: 'iPhone, xe máy, bàn ghế...',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: EdgeInsets.zero,
                        ),
                        label: const Text(
                          'Tất cả danh mục',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 15),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          padding: EdgeInsets.zero,
                        ),
                        label: const Text(
                          'Mới nhất',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.swap_vert, size: 15),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, index) {
                        final filter = filters[index];
                        final selected = _selected == filter;
                        return ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: AppColors.primarySoft,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                          onSelected: (_) => setState(() => _selected = filter),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '1.284 tin phù hợp',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'TP. Hồ Chí Minh',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListingGrid(
                    listings: [
                      ...figmaPreviewListings,
                      ...figmaPreviewListings.take(2),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
