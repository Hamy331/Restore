import 'package:restore/l10n/app_localizations.dart';

/// Hàm lấy chuỗi đa ngôn ngữ, giúp model không phải lưu chuỗi đã dịch
typedef L10nText = String Function(AppLocalizations l10n);

/// Một lựa chọn trong danh sách (VD: Hãng, Màu sắc, Khu vực)
class ListingOption {
  const ListingOption(this.value, {this.label});

  /// Giá trị lưu xuống dữ liệu / gửi lên API
  final String value;

  /// Null khi giá trị là tên riêng không cần dịch (VD: Apple, 128 GB)
  final L10nText? label;

  String labelOf(AppLocalizations l10n) => label?.call(l10n) ?? value;
}

extension ListingOptionListX on List<ListingOption> {
  ListingOption? byValue(String? value) {
    for (final option in this) {
      if (option.value == value) return option;
    }
    return null;
  }
}
