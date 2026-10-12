import 'package:restore/l10n/app_localizations.dart';

/// Tình trạng sản phẩm, dùng chung cho mọi danh mục.
/// Giá trị API khớp enum ListingCondition trong prisma/schema.prisma.
enum ListingCondition {
  newItem('NEW'),
  likeNew('LIKE_NEW'),
  usedGood('USED_GOOD'),
  usedFair('USED_FAIR'),
  forParts('FOR_PARTS');

  const ListingCondition(this.apiValue);

  final String apiValue;

  static ListingCondition? fromApi(String? value) {
    for (final condition in values) {
      if (condition.apiValue == value) return condition;
    }
    return null;
  }

  String label(AppLocalizations l10n) => switch (this) {
    newItem => l10n.conditionNew,
    likeNew => l10n.conditionLikeNew,
    usedGood => l10n.conditionUsedGood,
    usedFair => l10n.conditionUsedFair,
    forParts => l10n.conditionForParts,
  };

  String description(AppLocalizations l10n) => switch (this) {
    newItem => l10n.conditionNewDesc,
    likeNew => l10n.conditionLikeNewDesc,
    usedGood => l10n.conditionUsedGoodDesc,
    usedFair => l10n.conditionUsedFairDesc,
    forParts => l10n.conditionForPartsDesc,
  };
}
