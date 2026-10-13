import 'package:restore/l10n/app_localizations.dart';

/// Các bước của luồng đăng tin, thứ tự khai báo chính là thứ tự hiển thị
enum CreateListingStep {
  category('/create-listing/category'),
  basicInfo('/create-listing/basic-info'),
  details('/create-listing/details');

  const CreateListingStep(this.path);

  final String path;

  int get number => index + 1;
  static int get total => values.length;

  String title(AppLocalizations l10n) => switch (this) {
    category => l10n.chooseCategoryTitle,
    basicInfo => l10n.stepBasicInfoTitle,
    details => l10n.detailedInfoTitle,
  };

  /// Nhãn ngắn hiển thị dưới thanh tiến trình
  String shortTitle(AppLocalizations l10n) => switch (this) {
    category => l10n.stepShortCategory,
    basicInfo => l10n.stepShortBasicInfo,
    details => l10n.stepShortDetails,
  };

  static List<String> shortTitles(AppLocalizations l10n) => [
    for (final step in values) step.shortTitle(l10n),
  ];
}

/// Trang xem trước không phải một bước nên khai báo riêng
const String createListingPreviewPath = '/create-listing/preview';
