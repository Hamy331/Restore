import 'package:flutter/material.dart';
import '../../../shared/widgets/feedback_view.dart';

class TFoundationPlaceholderLayout extends StatelessWidget {
  const TFoundationPlaceholderLayout({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: FeedbackView(
        icon: icon,
        title: title,
        message: message,
      ),
    );
  }
}