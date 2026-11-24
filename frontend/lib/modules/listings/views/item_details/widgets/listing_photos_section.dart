import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/app_image_source_sheet.dart';
import 'package:restore/shared/widgets/app_photo_picker_grid.dart';
import '../../../bloc/create_listing/create_listing_bloc.dart';
import '../../../bloc/create_listing/create_listing_event.dart';
import '../../../models/listing_draft.dart';
import 'listing_form_widgets.dart';

/// Ảnh sản phẩm: chọn ảnh, xóa ảnh, chạm để đặt ảnh bìa
class ListingPhotosSection extends StatefulWidget {
  const ListingPhotosSection({super.key, required this.images, this.errorText});

  final List<String> images;
  final String? errorText;

  @override
  State<ListingPhotosSection> createState() => _ListingPhotosSectionState();
}

class _ListingPhotosSectionState extends State<ListingPhotosSection> {
  bool _isPicking = false;

  Future<void> _onAddPhotos() async {
    final l10n = AppLocalizations.of(context)!;
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
      if (paths.isNotEmpty && mounted) {
        context.read<CreateListingBloc>().add(PhotosAdded(paths));
      }
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
    final bloc = context.read<CreateListingBloc>();
    final images = widget.images;
    return ListingLabeledField(
      label: l10n.listingPhotosLabel(ListingDraft.maxImages),
      errorText: widget.errorText,
      trailing: Text(
        l10n.photoCount(images.length, ListingDraft.maxImages),
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPhotoPickerGrid(
            images: images,
            maxImages: ListingDraft.maxImages,
            hasError: widget.errorText != null,
            onAddTap: _onAddPhotos,
            onRemove: (index) => bloc.add(PhotoRemoved(index)),
            onSetCover: (index) => bloc.add(CoverPhotoSet(index)),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 8),
            Text(l10n.coverImageHint, style: ListingFormStyle.subtitle),
          ],
        ],
      ),
    );
  }
}
