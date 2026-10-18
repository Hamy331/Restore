import 'package:flutter/material.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'choose_category_mobile_view.dart';

class ChooseCategoryView extends StatelessWidget {
  const ChooseCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TResponsiveLayout(mobile: ChooseCategoryMobileView());
  }
}
