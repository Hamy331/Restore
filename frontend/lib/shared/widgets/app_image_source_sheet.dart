import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/media_picker_service.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'app_option_sheet.dart';

/// Hỏi người dùng muốn chụp ảnh mới hay chọn từ thư viện
Future<MediaSource?> showAppImageSourceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppOptionSheet<MediaSource>(
    context,
    title: l10n.addPhotos,
    options: [
      AppSheetOption(MediaSource.camera, l10n.takePhoto, icon: AppIcons.camera),
      AppSheetOption(
        MediaSource.gallery,
        l10n.chooseFromGallery,
        icon: AppIcons.gallery,
      ),
    ],
  );
}
