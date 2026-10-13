import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'listing_preview_mobile_view.dart';

class ListingPreviewView extends StatelessWidget {
  const ListingPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TResponsiveLayout(mobile: ListingPreviewMobileView());
  }
}
