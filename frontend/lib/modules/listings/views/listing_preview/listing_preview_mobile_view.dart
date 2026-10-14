import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/animations/fade_slide_in.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../bloc/create_listing/create_listing_bloc.dart';
import '../../bloc/create_listing/create_listing_event.dart';
import '../../bloc/create_listing/create_listing_state.dart';
import 'widgets/listing_preview_description_card.dart';
import 'widgets/listing_preview_details_card.dart';
import 'widgets/listing_preview_gallery.dart';
import 'widgets/listing_preview_notice.dart';
import 'widgets/listing_preview_summary_card.dart';

/// Xem trước tin đăng như người mua sẽ thấy
class ListingPreviewMobileView extends StatelessWidget {
  const ListingPreviewMobileView({super.key});

  void _onPublish(BuildContext context) {
    // Quay về bước 3 để bước 3 xử lý kết quả (báo lỗi hoặc hoàn tất)
    final bloc = context.read<CreateListingBloc>();
    context.pop();
    bloc.add(const PublishRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(AppIcons.back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            l10n.listingPreviewTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: BlocBuilder<CreateListingBloc, CreateListingState>(
          builder: (context, state) {
            final sections = <Widget>[
              const ListingPreviewNotice(),
              ListingPreviewGallery(images: state.draft.images),
              ListingPreviewSummaryCard(state: state),
              ListingPreviewDescriptionCard(draft: state.draft),
              if (state.category?.attributes.isNotEmpty ?? false)
                ListingPreviewDetailsCard(state: state),
              Text(
                l10n.directArrangementNote,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ];
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) =>
                  FadeSlideIn(index: index, child: sections[index]),
            );
          },
        ),
        bottomNavigationBar: AppBottomActionBar(
          secondaryLabel: l10n.editAction,
          onSecondary: () => context.pop(),
          primaryLabel: l10n.publishListing,
          onPrimary: () => _onPublish(context),
        ),
      ),
    );
  }
}
