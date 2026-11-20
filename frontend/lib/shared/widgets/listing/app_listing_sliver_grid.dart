import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    return SliverGrid.builder(
      gridDelegate: _ListingGridDelegate(maxCardWidth, spacing),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, items[index]),
    );
  }
}

class _ListingGridDelegate extends SliverGridDelegate {
  const _ListingGridDelegate(this.maxCardWidth, this.spacing);
  final double maxCardWidth;
  final double spacing;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width = constraints.crossAxisExtent;
    final columns = ((width + spacing) / (maxCardWidth + spacing)).ceil().clamp(
      2,
      6,
    );
    final cardWidth = (width - spacing * (columns - 1)) / columns;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      mainAxisExtent: AppListingCard.heightFor(cardWidth),
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(_ListingGridDelegate oldDelegate) =>
      maxCardWidth != oldDelegate.maxCardWidth ||
      spacing != oldDelegate.spacing;
}
