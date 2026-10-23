import 'package:restore/l10n/app_localizations.dart';

/// Cách một shop được xác minh (cột verificationType của bảng Shop, đề xuất
/// trong `backend/docs/trusted-shops.md`).
enum ShopVerificationType {
  /// Shop gốc của thương hiệu (nhãn hàng tự mở hoặc nhà phân phối chính thức)
  officialBrand('OFFICIAL_BRAND'),

  /// Shop được admin ReStore kiểm tra giấy tờ và cấp chứng nhận
  certified('CERTIFIED');

  const ShopVerificationType(this.apiValue);

  final String apiValue;

  static ShopVerificationType? fromApi(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  String label(AppLocalizations l10n) => switch (this) {
    officialBrand => l10n.shopVerificationOfficial,
    certified => l10n.shopVerificationCertified,
  };

  String description(AppLocalizations l10n) => switch (this) {
    officialBrand => l10n.shopVerificationOfficialDesc,
    certified => l10n.shopVerificationCertifiedDesc,
  };
}
