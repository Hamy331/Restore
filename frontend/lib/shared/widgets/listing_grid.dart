import 'package:flutter/material.dart';
import '../../modules/listings/domain/entities/listing_preview.dart';
import 'listing_card.dart';

class ListingGrid extends StatelessWidget {
  const ListingGrid({
    required this.listings,
    this.shrinkWrap = true,
    super.key,
  });
  final List<ListingPreview> listings;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: listings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth <= 360 ? .67 : .70,
          ),
          itemBuilder: (_, index) => ListingCard(listing: listings[index]),
        );
      },
    );
  }
}
