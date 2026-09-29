import 'package:flutter/material.dart';
import '../../../shared/widgets/feedback_view.dart';

class FoundationPlaceholderView extends StatelessWidget {
  const FoundationPlaceholderView({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FeedbackView(icon: icon, title: title, message: message),
  );
}
