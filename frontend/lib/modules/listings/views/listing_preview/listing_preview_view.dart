import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/gallery/app_image_gallery.dart';
import '../../../plans/views/plans/plans_view.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import '../../utils/attribute_value_formatter.dart';
import '../../utils/listing_save_error.dart';
import '../../widgets/create_listing_scaffold.dart';
import '../../widgets/edit_listing_notice.dart';
import '../../widgets/listing_display_days_card.dart';
import '../../widgets/posting_limit_sheet.dart';
import '../item_details/widgets/duplicate_listing_sheet.dart';
import '../listing_details/widgets/content_flag_sheet.dart';

/// Bước 3: xem lại tin như người mua sẽ thấy, chọn thời gian hiển thị và
/// đăng tin (sửa tin đã đăng thì gửi duyệt lại)
class ListingPreviewView extends StatelessWidget {
  const ListingPreviewView({super.key});

  void _onPublishStateChanged(BuildContext context, CreateListingState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.publishStatus) {
      case RequestStatus.success when state.isEditing:
        TSnackBarHelper.showSuccess(
          context,
          message: state.isEditingApproved
              ? l10n.editSubmittedLive
              : l10n.editSubmitted,
        );
        // Thoát cả luồng sửa tin, về trang đã mở nó (chi tiết tin, Tài khoản)
        exitCreateListingFlow(context, true);
      case RequestStatus.success:
        TSnackBarHelper.showSuccess(context, message: l10n.listingSubmitted);
        context.go('/home');
      case RequestStatus.failure:
        TSnackBarHelper.showError(
          context,
          message: listingSaveErrorText(
            l10n,
            state.saveError,
            fallback: l10n.publishFailed,
          ),
        );
      case RequestStatus.idle || RequestStatus.loading:
        break;
    }
  }

  /// Còn thiếu thông tin: quay về bước 2 để người dùng thấy lỗi
  void _onInvalidPublish(BuildContext context, CreateListingState state) {
    final l10n = AppLocalizations.of(context)!;
    TSnackBarHelper.showWarning(context, message: l10n.missingRequiredFields);
    if (context.canPop()) context.pop();
  }

  Future<void> _onPostingLimitHit(
    BuildContext context,
    CreateListingState state,
  ) async {
    final category = state.category;
    final quota = state.quota;
    if (category == null || quota == null) return;
    final bloc = context.read<CreateListingBloc>();
    final action = await showPostingLimitSheet(
      context,
      category: category,
      quota: quota,
      atPublish: true,
    );
    if (!context.mounted) return;
    switch (action) {
      case PostingLimitAction.payWithCredits:
        bloc.add(const PublishRequested(payWithCredits: true));
      case PostingLimitAction.topUp:
        final price = quota.forCategory(category.id).extraCredits ?? 0;
        await context.push(
          CreditTopupView.location(need: price - quota.walletAvailable),
        );
        // Quay lại sau khi nạp: tải lại số dư để lần bấm Đăng sau dùng được
        bloc.add(const PostingQuotaRequested());
      case PostingLimitAction.upgradePlan:
        await context.push(PlansView.path);
        bloc.add(const PostingQuotaRequested());
      // Giữ nguyên nội dung đã nhập, chỉ quay về bước 1 để đổi chuyên mục
      case PostingLimitAction.chooseAnotherCategory:
        context.go(CreateListingStep.category.path);
      case null:
        break;
    }
  }

  /// Ví không đủ xu cho ngày hiển thị thêm: nạp xu rồi đăng lại, hoặc đăng
  /// luôn với số ngày miễn phí của chuyên mục
  Future<void> _onCreditsShort(
    BuildContext context,
    CreateListingState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<CreateListingBloc>();
    final free = state.categoryQuota?.displayDays ?? 0;
    final choice = await showAppOptionSheet<String>(
      context,
      title: l10n.displayDaysShortTitle,
      subtitle: l10n.displayDaysShortBody(state.creditsMissing),
      icon: AppIcons.wallet,
      options: [
        AppSheetOption('topup', l10n.postingTopUp, icon: AppIcons.wallet),
        AppSheetOption(
          'free',
          l10n.displayDaysUseFree(free),
          icon: AppIcons.calendar,
        ),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'topup':
        await context.push(
          CreditTopupView.location(need: state.creditsMissing),
        );
        bloc.add(const PostingQuotaRequested());
      case 'free':
        bloc
          ..add(DisplayDaysChanged(startsAt: state.draft.startsAt))
          ..add(const PublishRequested());
    }
  }

  /// Đã có tin giống vậy: tin cũ đang hiển thị thì mời xem tin cũ; đã ẩn /
  /// hết hạn thì mời kích hoạt lại tin cũ (ở trang tài khoản) hoặc vẫn đăng mới
  Future<void> _onDuplicate(
    BuildContext context,
    CreateListingState state,
  ) async {
    final duplicate = state.duplicate;
    if (duplicate == null) return;
    final bloc = context.read<CreateListingBloc>();
    final action = await showDuplicateListingSheet(
      context,
      active: duplicate.active,
    );
    if (!context.mounted) return;
    switch (action) {
      case DuplicateListingAction.postNew:
        bloc.add(
          PublishRequested(
            payWithCredits: state.duplicatePaid,
            allowDuplicate: true,
          ),
        );
      case DuplicateListingAction.openOld:
        context.go(
          duplicate.active ? '/listings/${duplicate.listingId}' : '/account',
        );
      case null:
        break;
    }
  }

  /// Nội dung có SĐT, link hoặc từ ngữ hàng cấm: mời sửa lại, hoặc vẫn gửi
  /// để quản trị viên xem xét
  Future<void> _onContentFlagged(
    BuildContext context,
    CreateListingState state,
  ) async {
    final bloc = context.read<CreateListingBloc>();
    final sendAnyway = await showContentFlagSheet(
      context,
      flags: state.contentFlags,
    );
    if (!context.mounted || sendAnyway != true) return;
    bloc.add(
      PublishRequested(payWithCredits: state.duplicatePaid, acceptFlags: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<CreateListingBloc>();
    final desktop = isDesktopLayout(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.publishStatus != current.publishStatus,
          listener: _onPublishStateChanged,
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.invalidPublishAttempts != current.invalidPublishAttempts,
          listener: _onInvalidPublish,
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.postingLimitHits != current.postingLimitHits,
          listener: _onPostingLimitHit,
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.duplicateHits != current.duplicateHits,
          listener: _onDuplicate,
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.contentFlagHits != current.contentFlagHits,
          listener: _onContentFlagged,
        ),
        BlocListener<CreateListingBloc, CreateListingState>(
          listenWhen: (previous, current) =>
              previous.creditsShortHits != current.creditsShortHits,
          listener: _onCreditsShort,
        ),
      ],
      child: BlocBuilder<CreateListingBloc, CreateListingState>(
        builder: (context, state) {
          final gallery = ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppImageGallery(
                images: state.draft.images,
                heroTag: 'listing-preview',
              ),
            ),
          );
          final summary = _PreviewSummary(state: state);

          return CreateListingScaffold(
            step: CreateListingStep.preview,
            title: l10n.previewPublishTitle,
            maxWidth: desktop ? 960 : createListingMaxWidth,
            bottomBar: CreateListingBottomBar(
              primaryLabel: state.isEditing
                  ? l10n.editSubmit
                  : l10n.publishListing,
              isLoading: state.publishStatus == RequestStatus.loading,
              onPrimary: () => bloc.add(const PublishRequested()),
              onBack: () => context.pop(),
            ),
            children: [
              if (state.isEditing) ...[
                const EditListingNotice(),
                const SizedBox(height: 16),
              ],
              _Notice(text: l10n.previewNotice),
              const SizedBox(height: 20),
              if (desktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 380, child: gallery),
                    const SizedBox(width: 28),
                    Expanded(child: summary),
                  ],
                )
              else ...[
                gallery,
                const SizedBox(height: 20),
                summary,
              ],
              const SizedBox(height: 24),
              _PreviewDetails(state: state),
              // Sửa tin không đổi thời gian hiển thị (muốn thêm thì gia hạn)
              if (!state.isEditing) ...[
                const SizedBox(height: 20),
                const ListingDisplayDaysCard(),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.directArrangementNote,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.actionSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.visible,
            size: 18,
            color: AppColors.actionPrimaryDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.actionPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiêu đề, giá, các nhãn (danh mục, tình trạng, giá cố định...), khu vực
class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.state});

  final CreateListingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final draft = state.draft;
    final category = state.category;
    final price = draft.price;
    final vehicle = ListingCondition.usesVehicleScale(
      draft.categoryId,
      draft.subcategoryId,
    );
    final tags = [
      ?(category?.subcategory?.name ?? category?.name)?.of(context),
      if (category?.hasCondition ?? true)
        ?draft.condition?.labelFor(l10n, vehicle: vehicle),
      if (!draft.isFree)
        draft.fixedPrice ? l10n.fixedPriceTitle : l10n.negotiable,
      if (draft.multipleUnits) l10n.multipleUnitsTag,
      if (draft.meetUp) l10n.meetUpTitle,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.title.trim().isEmpty ? l10n.notSpecified : draft.title.trim(),
          style: const TextStyle(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              draft.isFree
                  ? l10n.priceFree
                  : price == null
                  ? l10n.notSpecified
                  : CurrencyFormatter.formatVnd(price, locale: locale),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: draft.isFree ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in tags) _Tag(label: tag)],
        ),
        if (draft.address case final address?) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                AppIcons.location,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.areaLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Mô tả và bảng thông tin chi tiết (chỉ phần người bán đã nhập)
class _PreviewDetails extends StatelessWidget {
  const _PreviewDetails({required this.state});

  final CreateListingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = state.draft.description.trim();
    final rows = <(String, String)>[
      for (final attribute
          in state.category?.attributes ?? const <CategoryAttributeModel>[])
        if (AttributeValueFormatter.format(
              context,
              attribute,
              state.draft.attributes[attribute.key],
            )
            case final value?)
          (attribute.label.of(context), value),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isNotEmpty) ...[
          _SectionTitle(l10n.detailedInfoTitle),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
        if (description.isNotEmpty) ...[
          _SectionTitle(l10n.productDescription),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
    );
  }
}
