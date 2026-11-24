import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/modules/search/utils/category_matches.dart';
import 'package:restore/shared/widgets/app_category_icon.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import '../../../plans/views/plans/plans_view.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import '../../models/posting_quota.dart';
import '../../widgets/create_listing_scaffold.dart';
import '../../widgets/posting_limit_sheet.dart';
import '../listing_drafts/listing_drafts_view.dart';
import 'widgets/category_list_skeleton.dart';
import 'widgets/category_quota_label.dart';
import 'widgets/drafts_banner.dart';
import 'widgets/posting_quota_banner.dart';

/// Bước 1: chọn danh mục rồi danh mục con. Có ô tìm theo tên danh mục /
/// danh mục con; chuyên mục đã hết suất đăng hiện ổ khoá.
class ChooseCategoryView extends StatefulWidget {
  const ChooseCategoryView({super.key});

  @override
  State<ChooseCategoryView> createState() => _ChooseCategoryViewState();
}

class _ChooseCategoryViewState extends State<ChooseCategoryView> {
  final _search = TextEditingController();
  String _query = '';

  /// Danh mục cha đang mở để chọn danh mục con (null = danh sách cha)
  CategoryModel? _parent;

  /// Chặn chạm liên tiếp khi đang kiểm tra hạn mức
  bool _selecting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openParent(CategoryModel category) {
    // Danh mục chưa chia con, hoặc chỉ một con: chọn luôn
    if (!category.hasSubcategories) {
      unawaited(_select(category, ''));
    } else if (category.subcategories.length == 1) {
      unawaited(_select(category, category.subcategories.first.id));
    } else {
      setState(() => _parent = category);
    }
  }

  Future<void> _select(CategoryModel category, String subcategoryId) async {
    if (_selecting) return;
    _selecting = true;
    try {
      if (!await _checkQuota(category) || !mounted) return;
      context.read<CreateListingBloc>().add(
        CategorySelected(category.id, subcategoryId),
      );
      // Điều hướng ngay khi chạm, không chờ state đổi: chọn lại đúng danh
      // mục cũ thì state không đổi
      unawaited(context.push(CreateListingStep.details.path));
    } finally {
      _selecting = false;
    }
  }

  /// Lấy hạn mức (dùng lại bản vừa tải) trước khi cho vào trang tạo tin. Hết suất
  /// miễn phí thì báo ngay, cho trả xu / nạp xu / nâng gói trước khi người
  /// bán mất công điền tin. true khi được đăng tiếp.
  Future<bool> _checkQuota(CategoryModel category) async {
    final bloc = context.read<CreateListingBloc>();
    final done = Completer<void>();
    // Hạn mức vừa tải trong 1 phút thì dùng luôn, không bắt người dùng chờ
    // gọi lại API mỗi lần chạm (backend vẫn kiểm tra khi đăng)
    bloc.add(
      PostingQuotaRequested(done: done, maxAge: const Duration(minutes: 1)),
    );
    await done.future.timeout(const Duration(seconds: 8), onTimeout: () {});
    if (!mounted) return false;
    final quota = bloc.state.quota;
    if (quota == null || !quota.isFull(category.id)) return true;
    final action = await showPostingLimitSheet(
      context,
      category: category,
      quota: quota,
    );
    if (!mounted) return false;
    switch (action) {
      case PostingLimitAction.payWithCredits:
        return true;
      case PostingLimitAction.topUp:
        final price = quota.forCategory(category.id).extraCredits ?? 0;
        await context.push(
          CreditTopupView.location(need: price - quota.walletAvailable),
        );
        bloc.add(const PostingQuotaRequested());
        return false;
      case PostingLimitAction.upgradePlan:
        await context.push(PlansView.path);
        bloc.add(const PostingQuotaRequested());
        return false;
      case PostingLimitAction.chooseAnotherCategory || null:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parent = _parent;

    return PopScope(
      // Đang xem danh mục con: nút quay lại hệ thống về danh sách cha
      canPop: parent == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && parent != null) setState(() => _parent = null);
      },
      child: CreateListingScaffold(
        step: CreateListingStep.category,
        title: l10n.chooseCategoryTitle,
        showSaveDraft: false,
        children: [
          BlocBuilder<CreateListingBloc, CreateListingState>(
            buildWhen: (previous, current) =>
                previous.chooseCategoryReady != current.chooseCategoryReady ||
                previous.categories != current.categories ||
                previous.categoriesStatus != current.categoriesStatus ||
                previous.quota != current.quota ||
                previous.drafts != current.drafts ||
                previous.hasMoreDrafts != current.hasMoreDrafts ||
                previous.draft.categoryId != current.draft.categoryId ||
                previous.draft.subcategoryId != current.draft.subcategoryId,
            builder: (context, state) {
              // Chờ tải xong danh mục, hạn mức và nháp rồi mới hiện: hiện
              // danh mục trước khi biết hạn mức thì dễ chọn nhầm chuyên mục
              // đã hết suất
              if (!state.chooseCategoryReady) {
                return const CategoryListSkeleton();
              }
              if (state.categoriesStatus == RequestStatus.failure) {
                return AppLoadErrorView(
                  title: l10n.loadCategoriesFailedTitle,
                  onRetry: () => context.read<CreateListingBloc>().add(
                    const CategoriesRequested(),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.quota != null && parent == null) ...[
                    PostingQuotaBanner(quota: state.quota!),
                    const SizedBox(height: 12),
                  ],
                  if (state.drafts.isNotEmpty && parent == null) ...[
                    DraftsBanner(
                      count: state.drafts.length,
                      hasMore: state.hasMoreDrafts,
                      onTap: () => context.push(ListingDraftsView.path),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _SearchField(
                    controller: _search,
                    hint: l10n.categorySearchHint,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 4),
                  _buildList(context, state),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, CreateListingState state) {
    final l10n = AppLocalizations.of(context)!;
    String name(CategoryModel category) => category.name.of(context);
    bool locked(CategoryModel category) =>
        state.quota?.isFull(category.id) ?? false;
    CategoryPostingQuota? quotaOf(CategoryModel category) =>
        state.quota?.forCategory(category.id);
    final draft = state.draft;

    // Đang tìm: danh mục cha và danh mục con khớp từ khoá
    if (_query.trim().isNotEmpty) {
      final matches = matchCategories(
        state.categories,
        _query,
        (text) => text.of(context),
        limit: 50,
      );
      if (matches.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            l10n.categorySearchEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      return Column(
        children: [
          for (final match in matches)
            match.sub == null
                ? _CategoryRow(
                    title: name(match.parent),
                    imageUrl: match.parent.imageUrl,
                    iconKey: match.parent.iconKey,
                    isLocked: locked(match.parent),
                    onTap: () {
                      _search.clear();
                      setState(() => _query = '');
                      _openParent(match.parent);
                    },
                  )
                : _CategoryRow(
                    title: match.sub!.name.of(context),
                    subtitle: l10n.searchSubcategorySuggestion(
                      name(match.parent),
                    ),
                    isLocked: locked(match.parent),
                    onTap: () => _select(match.parent, match.sub!.id),
                  ),
        ],
      );
    }

    final parent = _parent;
    if (parent != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryRow(
            title: name(parent),
            imageUrl: parent.imageUrl,
            iconKey: parent.iconKey,
            leading: AppIcons.back,
            emphasized: true,
            onTap: () => setState(() => _parent = null),
          ),
          for (final sub in parent.subcategories)
            _CategoryRow(
              title: sub.name.of(context),
              indent: true,
              isSelected:
                  draft.categoryId == parent.id &&
                  draft.subcategoryId == sub.id,
              isLocked: locked(parent),
              onTap: () => _select(parent, sub.id),
            ),
        ],
      );
    }

    return Column(
      children: [
        for (final category in state.categories)
          _CategoryRow(
            title: name(category),
            imageUrl: category.imageUrl,
            iconKey: category.iconKey,
            isSelected: draft.categoryId == category.id,
            isLocked: locked(category),
            footer: switch (quotaOf(category)) {
              final quota? when quota.used > 0 => CategoryQuotaLabel(
                quota: quota,
              ),
              _ => null,
            },
            onTap: () => _openParent(category),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(
          AppIcons.search,
          size: 20,
          color: AppColors.textSecondary,
        ),
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(AppIcons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        filled: true,
        fillColor: AppColors.fill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.actionPrimary),
        ),
      ),
    );
  }
}

/// Một dòng danh mục: icon, tên, (mô tả nhỏ), mũi tên hoặc ổ khoá
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.iconKey,
    this.footer,
    this.leading,
    this.isSelected = false,
    this.isLocked = false,
    this.emphasized = false,
    this.indent = false,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? iconKey;
  final Widget? footer;

  /// Icon thay cho mũi tên cuối dòng, đặt ở đầu (nút quay lại danh sách cha)
  final IconData? leading;
  final bool isSelected;
  final bool isLocked;
  final bool emphasized;
  final bool indent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasIcon = imageUrl != null || iconKey != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: EdgeInsets.fromLTRB(indent ? 12 : 0, 12, 0, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 12),
            ],
            if (hasIcon) ...[
              Opacity(
                opacity: isLocked ? 0.45 : 1,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: AppCategoryIcon(
                    imageUrl: imageUrl,
                    iconKey: iconKey,
                    size: 36,
                    fallbackSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: emphasized || isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isLocked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (footer != null) ...[const SizedBox(height: 6), footer!],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (leading == null)
              Icon(
                isLocked
                    ? AppIcons.lock
                    : isSelected
                    ? AppIcons.check
                    : AppIcons.chevronRight,
                size: 22,
                color: isSelected
                    ? AppColors.actionPrimary
                    : AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
