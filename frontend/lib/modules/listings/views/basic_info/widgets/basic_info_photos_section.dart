import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/app_field_message.dart';
import 'package:restore/shared/widgets/app_image_source_sheet.dart';
import 'package:restore/shared/widgets/app_photo_picker_grid.dart';
import 'package:restore/shared/widgets/app_required_label.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import '../../../models/listing_draft.dart';

/// Phần ảnh sản phẩm: chọn ảnh bằng image_picker, xóa ảnh, đặt ảnh bìa
class BasicInfoPhotosSection extends StatefulWidget {
  final List<String> images;
  final bool hasError;

  const BasicInfoPhotosSection({
    super.key,
    required this.images,
    this.hasError = false,
  });

  @override
  State<BasicInfoPhotosSection> createState() => _BasicInfoPhotosSectionState();
}

class _BasicInfoPhotosSectionState extends State<BasicInfoPhotosSection> {
  bool _isPicking = false;

  CreateListingBloc get _bloc => context.read<CreateListingBloc>();

  Future<void> _onAddPhotos(AppLocalizations l10n) async {
    if (_isPicking) return;
    final remaining = ListingDraft.maxImages - widget.images.length;
    if (remaining <= 0) {
      TSnackBarHelper.showWarning(
        context,
        message: l10n.photoLimitReached(ListingDraft.maxImages),
      );
      return;
    }

    final source = await showAppImageSourceSheet(context);
    if (source == null || !mounted) return;

    _isPicking = true;
    try {
      final paths = await context.read<MediaPickerService>().pickImages(
        source: source,
        limit: remaining,
      );
      if (paths.isNotEmpty) _bloc.add(PhotosAdded(paths));
    } on PlatformException {
      if (mounted) {
        TSnackBarHelper.showError(context, message: l10n.photoPickFailed);
      }
    } finally {
      _isPicking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final images = widget.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppRequiredLabel(
                text: l10n.listingPhotosLabel(ListingDraft.maxImages),
                isRequired: true,
                style: AppRequiredLabel.defaultStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              l10n.photoCount(images.length, ListingDraft.maxImages),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppPhotoPickerGrid(
          images: images,
          maxImages: ListingDraft.maxImages,
          hasError: widget.hasError,
          onAddTap: () => _onAddPhotos(l10n),
          onRemove: (index) => _bloc.add(PhotoRemoved(index)),
          onSetCover: (index) => _bloc.add(CoverPhotoSet(index)),
        ),
        AppFieldMessage(
          errorText: widget.hasError ? l10n.photosRequiredError : null,
          helperText: images.length > 1 ? l10n.coverImageHint : null,
        ),
      ],
    );
  }
}
