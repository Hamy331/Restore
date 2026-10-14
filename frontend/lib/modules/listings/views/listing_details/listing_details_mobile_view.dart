import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import '../../utils/listing_validator.dart';
import '../../widgets/create_listing_scaffold.dart';
import 'widgets/listing_attribute_field.dart';
import 'widgets/listing_condition_section.dart';
import 'widgets/listing_details_header.dart';
import 'widgets/listing_details_section.dart';

/// Bước 3: Tình trạng + thuộc tính theo danh mục (schema động), xem trước, đăng tin
class ListingDetailsMobileView extends StatelessWidget {
  const ListingDetailsMobileView({super.key});

  void _onPublishStateChanged(BuildContext context, CreateListingState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.publishStatus) {
      case RequestStatus.success:
        TSnackBarHelper.showSuccess(context, message: l10n.listingSubmitted);
        context.go('/home');
      case RequestStatus.failure:
        TSnackBarHelper.showError(context, message: l10n.publishFailed);
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
              primaryLabel: l10n.publishListing,
              isLoading: state.publishStatus == RequestStatus.loading,
              onPrimary: () => bloc.add(const PublishRequested()),
            ),
            children: [
              ListingDetailsHeader(category: category),
              const SizedBox(height: 14),
              ListingDetailsSection(
                title: l10n.conditionSectionTitle,
                isRequired: true,
                children: [
                  ListingConditionSection(
                    selected: state.draft.condition,
                    hasError: errors.containsKey(ListingValidator.conditionKey),
                    onSelected: (value) => bloc.add(ConditionChanged(value)),
                  ),
                ],
              ),
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
