import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';

/// Khung chung các trang ví xu: nền kính, hàng tiêu đề có nút quay lại,
/// nội dung [body] và thanh nút cuối trang [bottom] (tuỳ chọn).
class CreditPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final Widget body;
  final Widget? bottom;

  const CreditPageScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.body,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: bottom,
      body: AppGlassBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: AppPageTitleRow(
                  title: title,
                  subtitle: subtitle,
                  onBack: onBack,
                  trailing: trailing,
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
