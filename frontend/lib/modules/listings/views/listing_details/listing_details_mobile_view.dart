import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/modules/credits/views/credit_topup/credit_topup_view.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import '../../utils/listing_validator.dart';
import '../../widgets/create_listing_scaffold.dart';
import '../../widgets/posting_limit_sheet.dart';
import 'widgets/duplicate_listing_sheet.dart';
import 'widgets/listing_attribute_field.dart';
import 'widgets/listing_condition_section.dart';
import '../../widgets/edit_listing_notice.dart';
import '../../widgets/listing_display_days_card.dart';
import 'widgets/listing_details_header.dart';
import 'widgets/listing_details_section.dart';
import '../../utils/listing_save_error.dart';
import '../../../plans/views/plans/plans_view.dart';

/// Bước 3: Tình trạng + thuộc tính theo danh mục (schema động), xem trước, đăng tin
class ListingDetailsMobileView extends StatelessWidget {
  const ListingDetailsMobileView({super.key});

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
        Navigator.of(context, rootNavigator: true).pop(true);
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

  void _onInvalidPublish(BuildContext context, CreateListingState state) {
    final l10n = AppLocalizations.of(context)!;
    TSnackBarHelper.showWarning(context, message: l10n.missingRequiredFields);
    // Thiếu thông tin ở bước 2 thì quay lại bước 2 để người dùng thấy lỗi
    if (!state.isBasicInfoValid && context.canPop()) context.pop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<CreateListingBloc>();

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
              previous.creditsShortHits != current.creditsShortHits,
          listener: _onCreditsShort,
        ),
      ],
      child: BlocBuilder<CreateListingBloc, CreateListingState>(
        builder: (context, state) {
          final category = state.category;
          final attributes = category?.attributes ?? const [];
          final errors = state.detailErrors;

          return CreateListingScaffold(
            title: l10n.completeListingTitle,
            step: CreateListingStep.details,
            bottomBar: AppBottomActionBar(
              secondaryLabel: l10n.preview,
              onSecondary: () => context.push(createListingPreviewPath),
              primaryLabel: state.isEditing
                  ? l10n.editSubmit
                  : l10n.publishListing,
              isLoading: state.publishStatus == RequestStatus.loading,
              onPrimary: () => bloc.add(const PublishRequested()),
            ),
            children: [
              if (state.isEditing) ...[
                const EditListingNotice(),
                const SizedBox(height: 14),
              ],
              ListingDetailsHeader(category: category),
              // Thú cưng... không có tình trạng hàng
              if (category?.hasCondition ?? true) ...[
                const SizedBox(height: 14),
                ListingDetailsSection(
                  title: l10n.conditionSectionTitle,
                  isRequired: true,
                  children: [
                    ListingConditionSection(
                      selected: state.draft.condition,
                      hasError: errors.containsKey(
                        ListingValidator.conditionKey,
                      ),
                      onSelected: (value) => bloc.add(ConditionChanged(value)),
                    ),
                  ],
                ),
              ],
              if (attributes.isNotEmpty) ...[
                const SizedBox(height: 14),
                ListingDetailsSection(
                  title: l10n.categoryAttributesTitle,
                  children: [
                    for (final attribute in attributes)
                      ListingAttributeField(
                        // Key theo danh mục để ô nhập được tạo lại khi đổi danh mục
                        key: ValueKey('${category?.id}_${attribute.key}'),
                        attribute: attribute,
                        value: state.draft.attributes[attribute.key],
                        error: errors[attribute.key],
                        onChanged: (value) =>
                            bloc.add(AttributeChanged(attribute.key, value)),
                      ),
                  ],
                ),
              ],
              // Sửa tin không đổi thời gian hiển thị (muốn thêm ngày thì gia hạn)
              if (!state.isEditing) ...[
                const SizedBox(height: 14),
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
