import 'package:restore/l10n/app_localizations.dart';

/// 3 bước đăng tin, thứ tự khai báo chính là thứ tự hiển thị:
/// chọn danh mục → thông tin sản phẩm → xem trước & đăng tin
enum CreateListingStep {
  category('/create-listing/category'),
  details('/create-listing/details'),
  preview('/create-listing/preview');

  const CreateListingStep(this.path);

  final String path;

  int get number => index + 1;
  static int get total => values.length;

  String title(AppLocalizations l10n) => switch (this) {
    category => l10n.chooseCategoryTitle,
    details => l10n.itemDetailsTitle,
    preview => l10n.previewPublishTitle,
  };
}
