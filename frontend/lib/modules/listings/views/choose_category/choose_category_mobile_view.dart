import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/animations/fade_slide_in.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/glass/app_glass_container.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import 'package:restore/data/models/category_model.dart';
import '../../widgets/create_listing_scaffold.dart';
import 'widgets/category_card.dart';
import 'widgets/category_list_skeleton.dart';

/// Bước 1: Chọn danh mục (danh sách lấy từ API / dữ liệu mẫu)
class ChooseCategoryMobileView extends StatelessWidget {
  const ChooseCategoryMobileView({super.key});

  void _onSelect(BuildContext context, CategoryModel category) {
    context.read<CreateListingBloc>().add(CategorySelected(category.id));
    // Điều hướng ngay khi chạm, không chờ state đổi: nếu chọn lại đúng
    // danh mục cũ thì state không đổi và trang sẽ "đứng" (lỗi cũ)
    context.push(CreateListingStep.basicInfo.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CreateListingScaffold(
      title: l10n.createListing,
      step: CreateListingStep.category,
      showSaveDraft: false,
      children: [
        AppGlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  l10n.chooseCategorySubtitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              BlocBuilder<CreateListingBloc, CreateListingState>(
                buildWhen: (previous, current) =>
                    previous.categoriesStatus != current.categoriesStatus ||
                    previous.categories != current.categories,
                builder: (context, state) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (state.categoriesStatus) {
                    RequestStatus.success => _CategoryList(
                      categories: state.categories,
                      onSelect: (category) => _onSelect(context, category),
                    ),
                    RequestStatus.failure => FeedbackView(
                      icon: AppIcons.offline,
                      title: l10n.loadCategoriesFailedTitle,
                      message: l10n.loadCategoriesFailedMessage,
                      action: FilledButton(
                        onPressed: () => context.read<CreateListingBloc>().add(
                          const CategoriesRequested(),
                        ),
                        child: Text(l10n.retry),
                      ),
                    ),
                    _ => const CategoryListSkeleton(),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onSelect;

  const _CategoryList({required this.categories, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < categories.length; i++)
          FadeSlideIn(
            index: i,
            child: CategoryCard(
              title: categories[i].name.of(context),
              description: categories[i].description.of(context),
              imagePath: categories[i].imageUrl,
              fallbackIcon: AppIcons.forCategory(categories[i].iconKey),
              showBottomBorder: i < categories.length - 1,
              onTap: () => onSelect(categories[i]),
            ),
          ),
      ],
    );
  }
}
