import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
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
import '../../models/posting_quota.dart';
import 'package:restore/data/models/category_model.dart';
import '../../widgets/create_listing_scaffold.dart';
import '../../widgets/posting_limit_sheet.dart';
import 'widgets/category_card.dart';
import 'widgets/category_list_skeleton.dart';
import 'widgets/category_quota_label.dart';
import 'widgets/drafts_banner.dart';
import '../listing_drafts/listing_drafts_view.dart';
import 'widgets/posting_quota_banner.dart';
import '../../../plans/views/plans/plans_view.dart';

/// Bước 1: Chọn danh mục (danh sách lấy từ API / dữ liệu mẫu)
class ChooseCategoryMobileView extends StatelessWidget {
  const ChooseCategoryMobileView({super.key});

  /// Chặn chạm liên tiếp khi đang kiểm tra hạn mức
  static bool _selecting = false;

  Future<void> _onSelect(BuildContext context, CategoryModel category) async {
    if (_selecting) return;
    _selecting = true;
    try {
      await _checkAndOpen(context, category);
    } finally {
      _selecting = false;
    }
  }

  Future<void> _checkAndOpen(
    BuildContext context,
    CategoryModel category,
  ) async {
    final bloc = context.read<CreateListingBloc>();
    // Luôn lấy hạn mức mới nhất trước khi cho vào trang tạo tin: bấm nhanh
    // lúc hạn mức chưa tải xong (hoặc vừa đăng tin khác) không lọt qua được
    final done = Completer<void>();
    bloc.add(PostingQuotaRequested(done: done));
    await done.future.timeout(const Duration(seconds: 8), onTimeout: () {});
    if (!context.mounted) return;
    final quota = bloc.state.quota;
    // Hết suất miễn phí: báo ngay, cho chọn trả xu hoặc nạp xu trước khi
    // người bán mất công điền tin
    if (quota != null && quota.isFull(category.id)) {
      final action = await showPostingLimitSheet(
        context,
        category: category,
        quota: quota,
      );
      if (!context.mounted) return;
      switch (action) {
        case PostingLimitAction.payWithCredits:
          break;
        case PostingLimitAction.topUp:
          final price = quota.forCategory(category.id).extraCredits ?? 0;
          await context.push(
            CreditTopupView.location(need: price - quota.walletAvailable),
          );
          bloc.add(const PostingQuotaRequested());
          return;
        case PostingLimitAction.upgradePlan:
          await context.push(PlansView.path);
          bloc.add(const PostingQuotaRequested());
          return;
        case PostingLimitAction.chooseAnotherCategory || null:
          return;
      }
    }
    if (!context.mounted) return;
    bloc.add(CategorySelected(category.id));
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
        // Chờ tải xong danh mục, hạn mức và tin nháp rồi mới hiện tất cả cùng
        // lúc: hiện danh mục trước khi biết hạn mức thì người bán chọn nhầm
        // chuyên mục đã hết suất
        _ReadyGate(
          loading: const AppGlassContainer(child: CategoryListSkeleton()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocBuilder<CreateListingBloc, CreateListingState>(
                buildWhen: (previous, current) =>
                    previous.quota != current.quota,
                builder: (context, state) => state.quota == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostingQuotaBanner(quota: state.quota!),
                      ),
              ),
              BlocBuilder<CreateListingBloc, CreateListingState>(
                buildWhen: (previous, current) =>
                    previous.drafts != current.drafts ||
                    previous.hasMoreDrafts != current.hasMoreDrafts,
                builder: (context, state) => AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topCenter,
                  child: state.drafts.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DraftsBanner(
                            count: state.drafts.length,
                            hasMore: state.hasMoreDrafts,
                            onTap: () => context.push(ListingDraftsView.path),
                          ),
                        ),
                ),
              ),
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
                          previous.categoriesStatus !=
                              current.categoriesStatus ||
                          previous.categories != current.categories ||
                          previous.quota != current.quota,
                      builder: (context, state) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: switch (state.categoriesStatus) {
                          RequestStatus.success => _CategoryList(
                            categories: state.categories,
                            quota: state.quota,
                            onSelect: (category) =>
                                _onSelect(context, category),
                          ),
                          RequestStatus.failure => FeedbackView(
                            icon: AppIcons.offline,
                            title: l10n.loadCategoriesFailedTitle,
                            message: l10n.loadCategoriesFailedMessage,
                            action: FilledButton(
                              onPressed: () => context
                                  .read<CreateListingBloc>()
                                  .add(const CategoriesRequested()),
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
          ),
        ),
      ],
    );
  }
}

/// Hiện [loading] cho tới khi [CreateListingState.chooseCategoryReady], sau
/// đó hiện [child] một lần (tải lại hạn mức / nháp về sau không ẩn lại).
class _ReadyGate extends StatefulWidget {
  const _ReadyGate({required this.loading, required this.child});
  final Widget loading;
  final Widget child;

  @override
  State<_ReadyGate> createState() => _ReadyGateState();
}

class _ReadyGateState extends State<_ReadyGate> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CreateListingBloc, CreateListingState>(
        buildWhen: (previous, current) =>
            !_ready &&
            previous.chooseCategoryReady != current.chooseCategoryReady,
        builder: (context, state) {
          _ready = _ready || state.chooseCategoryReady;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _ready
                ? FadeSlideIn(key: const ValueKey('ready'), child: widget.child)
                : KeyedSubtree(
                    key: const ValueKey('loading'),
                    child: widget.loading,
                  ),
          );
        },
      );
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  final PostingQuota? quota;
  final ValueChanged<CategoryModel> onSelect;

  const _CategoryList({
    required this.categories,
    required this.quota,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [for (var i = 0; i < categories.length; i++) _buildCard(i)],
    );
  }

  Widget _buildCard(int i) {
    final categoryQuota = quota?.forCategory(categories[i].id);
    return Builder(
      builder: (context) => FadeSlideIn(
        index: i,
        child: CategoryCard(
          title: categories[i].name.of(context),
          description: categories[i].description.of(context),
          imagePath: categories[i].imageUrl,
          iconKey: categories[i].iconKey,
          showBottomBorder: i < categories.length - 1,
          isLocked: categoryQuota?.isFull ?? false,
          footer: categoryQuota == null || categoryQuota.used == 0
              ? null
              : CategoryQuotaLabel(quota: categoryQuota),
          onTap: () => onSelect(categories[i]),
        ),
      ),
    );
  }
}
