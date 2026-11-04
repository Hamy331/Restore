import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import 'feeds_mobile_view.dart';

/// Tab Bảng tin. Danh sách bài viết chưa làm; đầu trang có ô "Bạn đang
/// nghĩ gì?" mở màn hình viết bài.
class FeedsView extends StatelessWidget {
  const FeedsView({super.key});

  static const String path = '/feeds';

  @override
  Widget build(BuildContext context) =>
      const TResponsiveLayout(mobile: FeedsMobileView());
}
