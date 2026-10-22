import 'package:flutter/material.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import 'app_listing_card.dart';

/// Lưới thẻ tin dạng sliver: điện thoại 2 cột, màn rộng tự thêm cột
/// (mỗi cột tối đa [maxCardWidth]). Chiều cao thẻ theo [AppListingCard].
class AppListingSliverGrid extends StatelessWidget {
  final List<ListingCardItem> items;
  final Widget Function(BuildContext context, ListingCardItem item) itemBuilder;
  final double maxCardWidth;
  final double spacing;

  const AppListingSliverGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.maxCardWidth = 220,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = ((width + spacing) / (maxCardWidth + spacing))
            .ceil()
            .clamp(2, 6);
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: AppListingCard.heightFor(cardWidth),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(context, items[index]),
        );
      },
    );
  }
}
