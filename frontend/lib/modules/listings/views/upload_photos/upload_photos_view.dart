import 'package:flutter/material.dart';
import '../../../../core/ui/layouts/t_responsive_layout.dart';
import 'upload_photos_mobile_view.dart';

class UploadPhotosView extends StatelessWidget {
  const UploadPhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TResponsiveLayout(mobile: UploadPhotosMobileView());
  }
}
