import 'package:restore/l10n/app_localizations.dart';
import '../repositories/listings_repository.dart';

/// Câu báo lỗi khi lưu nháp / đăng tin theo nguyên nhân; không rõ thì [fallback]
String listingSaveErrorText(
  AppLocalizations l10n,
  Object? error, {
  required String fallback,
}) {
  if (error is! ListingSaveException) return fallback;
  return switch (error.imageProblem) {
    ListingImageProblem.tooLarge => l10n.listingImageTooLarge,
    ListingImageProblem.unsupported => l10n.listingImageUnsupported,
    ListingImageProblem.missing => l10n.listingImageMissing(
      error.imagePaths.length,
    ),
    null when error.isNetworkError => l10n.listingSaveNetworkError,
    null => error.serverMessage ?? fallback,
  };
}
