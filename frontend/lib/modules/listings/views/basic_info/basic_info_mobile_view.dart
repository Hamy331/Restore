import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import '../../models/create_listing_step.dart';
import '../../utils/listing_validator.dart';
import '../../widgets/create_listing_scaffold.dart';
import '../../widgets/edit_listing_notice.dart';
import 'widgets/basic_info_description_field.dart';
import 'widgets/basic_info_location_field.dart';
import 'widgets/basic_info_photos_section.dart';
import 'widgets/basic_info_quota_note.dart';
import 'widgets/basic_info_title_field.dart';
import 'widgets/basic_info_trade_section.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';

/// Bước 2: Ảnh, mô tả, tiêu đề, hình thức giao dịch, giá, địa chỉ
class BasicInfoMobileView extends StatelessWidget {
  const BasicInfoMobileView({super.key});

  void _onContinue(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<CreateListingBloc>();
    FocusScope.of(context).unfocus();
    bloc.add(const BasicInfoSubmitted());
    if (bloc.state.isBasicInfoValid) {
      context.push(CreateListingStep.details.path);
    } else {
      TSnackBarHelper.showWarning(context, message: l10n.missingRequiredFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CreateListingBloc, CreateListingState>(
      builder: (context, state) {
        final draft = state.draft;
        final errors = state.basicInfoErrors;
        final photos = BasicInfoPhotosSection(
          images: draft.images,
          hasError: errors.contains(ListingField.photos),
        );
        final fields = <Widget>[
          BasicInfoDescriptionField(
            hasError: errors.contains(ListingField.description),
          ),
          const SizedBox(height: 16),
          BasicInfoTitleField(hasError: errors.contains(ListingField.title)),
          const SizedBox(height: 16),
          BasicInfoTradeSection(
            tradeType: draft.tradeType,
            hasPriceError: errors.contains(ListingField.price),
            canSetOriginalPrice:
                (state.quota?.canSetOriginalPrice ?? false) ||
                draft.originalPrice != null,
            hasOriginalPriceError: errors.contains(ListingField.originalPrice),
            price: draft.price,
            originalPrice: draft.originalPrice,
          ),
          const SizedBox(height: 16),
          BasicInfoLocationField(
            address: draft.address,
            hasError: errors.contains(ListingField.location),
          ),
          const SizedBox(height: 16),
          // Loại người bán lấy theo gói tài khoản, không hỏi lúc đăng tin
          if (state.categoryQuota != null && !state.isEditing)
            BasicInfoQuotaNote(quota: state.categoryQuota!),
        ];

        return CreateListingScaffold(
          title: l10n.completeListingTitle,
          step: CreateListingStep.basicInfo,
          bottomBar: AppBottomActionBar(
            primaryLabel: l10n.continueBtn,
            onPrimary: () => _onContinue(context),
          ),
          children: [
            if (state.isEditing) ...[
              const EditListingNotice(),
              const SizedBox(height: 16),
            ],
            // Desktop: ảnh cột trái, thông tin cột phải
            if (isDesktopLayout(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 320, child: photos),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: fields,
                    ),
                  ),
                ],
              )
            else ...[
              photos,
              const SizedBox(height: 20),
              ...fields,
            ],
          ],
        );
      },
    );
  }
}
