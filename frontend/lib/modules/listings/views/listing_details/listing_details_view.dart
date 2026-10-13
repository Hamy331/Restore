import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'listing_details_mobile_view.dart';

class ListingDetailsView extends StatelessWidget {
  const ListingDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TResponsiveLayout(mobile: ListingDetailsMobileView());
  }
}
