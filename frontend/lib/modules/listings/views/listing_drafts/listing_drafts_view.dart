import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'listing_drafts_mobile_view.dart';

class ListingDraftsView extends StatelessWidget {
  const ListingDraftsView({super.key});

  /// Nằm trong luồng đăng tin để dùng chung CreateListingBloc
  static const String path = '/create-listing/drafts';

  @override
  Widget build(BuildContext context) {
    return const TResponsiveLayout(mobile: ListingDraftsMobileView());
  }
}
