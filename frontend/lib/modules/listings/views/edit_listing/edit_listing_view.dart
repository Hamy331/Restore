import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'edit_listing_mobile_view.dart';

/// Mở tin đã đăng để sửa: tải tin rồi chuyển sang bước 2 của luồng đăng tin
class EditListingView extends StatelessWidget {
  const EditListingView({super.key, required this.listingId});

  static const String path = '/create-listing/edit/:id';

  static String location(String id) =>
      '/create-listing/edit/${Uri.encodeComponent(id)}';

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return TResponsiveLayout(
      mobile: EditListingMobileView(listingId: listingId),
    );
  }
}
