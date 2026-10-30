import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/app_page_header.dart';

/// Đầu các trang "Báo khi có hàng": nút quay lại, tiêu đề kèm mô tả ngắn,
/// nút bên phải [trailing] (tuỳ chọn) và phần [bottom] bên dưới (ô tìm kiếm,
/// chip tiêu chí...). Nền trong suốt, đặt trong [WantedAlertGlassScaffold]
/// để thành kính mờ khi cuộn. Tự chừa thanh trạng thái.
class WantedAlertPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final Widget? bottom;

  const WantedAlertPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = this.bottom;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageTitleRow(
              title: title,
              subtitle: subtitle,
              onBack: onBack,
              trailing: trailing,
            ),
            if (bottom != null) ...[const SizedBox(height: 12), bottom],
          ],
        ),
      ),
    );
  }
}
