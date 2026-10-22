import 'package:flutter/material.dart';
import 'package:restore/core/theme/app_glass.dart';

/// Khung chờ danh sách thông báo khi đang tải lần đầu, chừa [topInset] cho
/// phần header nổi phía trên
class WantedAlertsSkeleton extends StatelessWidget {
  final double topInset;

  const WantedAlertsSkeleton({super.key, this.topInset = 0});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppGlass.fillSoft,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
