import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/shared/widgets/image_crop/image_crop.dart';
import 'package:restore/shared/widgets/image_crop/image_crop_view.dart';

import '../../../bloc/poster_editor_cubit.dart';
import '../../../widgets/poster_image.dart';

/// Khung ảnh 2:1: bấm để chọn ảnh từ thư viện, sau đó căn chỉnh / cắt vừa khung
class PosterImageField extends StatelessWidget {
  const PosterImageField({super.key, this.picker});

  final MediaPickerService? picker;

  /// Chọn ảnh từ thư viện rồi mở màn căn chỉnh khung 2:1
  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<PosterEditorCubit>();
    try {
      final paths = await (picker ?? MediaPickerService()).pickImages(
        source: MediaSource.gallery,
        limit: 1,
      );
      if (paths.isEmpty || !context.mounted) return;
      final source = await XFile(paths.first).readAsBytes();
      if (!context.mounted) return;
      await _crop(context, cubit, source);
    } on PlatformException {
      // người dùng từ chối quyền truy cập ảnh: giữ nguyên
    }
  }

  Future<void> _crop(
    BuildContext context,
    PosterEditorCubit cubit,
    Uint8List source,
  ) async {
    final cropped = await ImageCropView.open(
      context,
      source,
      frame: CropFrame.poster,
      title: AppLocalizations.of(context)!.spCropTitle,
    );
    if (cropped != null) cubit.setImage(cropped, source: source);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<PosterEditorCubit>().state;
    final path = state.imageUrl;
    final bytes = state.imageBytes;
    final source = state.sourceBytes;
    final error = state.showErrors && !state.hasImage
        ? l.spImageRequired
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('poster-image'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pick(context),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error != null ? AppColors.error : AppColors.border,
                  width: error != null ? 1.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  PosterImage(
                    path: path,
                    bytes: bytes,
                    placeholder: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          AppIcons.addPhoto,
                          size: 30,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.spPickImage,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.hasImage)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.gallery,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.spChangeImage,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (source != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('poster-image-adjust'),
              onPressed: () =>
                  _crop(context, context.read<PosterEditorCubit>(), source),
              icon: const Icon(AppIcons.zoomIn, size: 16),
              label: Text(l.spAdjust),
            ),
          )
        else
          const SizedBox(height: 8),
        Text(
          error ?? l.spImageHint,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: error != null ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
