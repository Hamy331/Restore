import 'package:flutter/widgets.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/data/models/enums/wanted_alert_match_level.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/listing_filter_labels.dart';

/// Một tiêu chí của thông báo để hiện dạng chip hoặc dòng (VD danh mục,
/// khoảng giá). [value] null là người dùng chưa đặt tiêu chí này.
class WantedAlertCriterion {
  final IconData icon;
  final String title;
  final String? value;

  /// Nhãn khi chưa đặt, VD "Mọi mức giá"
  final String fallback;

  const WantedAlertCriterion({
    required this.icon,
    required this.title,
    required this.value,
    required this.fallback,
  });

  bool get isSet => value != null;

  String get label => value ?? fallback;
}

/// Gom tiêu chí của thông báo (đang soạn hoặc đã lưu) thành nhãn hiển thị,
/// dùng chung cho thẻ ở trang quản lý, đầu trang chi tiết và form soạn.
class WantedAlertCriteria {
  WantedAlertCriteria._();

  static List<WantedAlertCriterion> of(
    BuildContext context, {
    required ListingFilter filter,
    String? categoryName,
    String? areaLabel,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return [
      WantedAlertCriterion(
        icon: AppIcons.category,
        title: l10n.wantedAlertCriteriaCategory,
        value: filter.categoryId == null ? null : categoryName ?? '…',
        fallback: l10n.wantedAlertAnyCategory,
      ),
      WantedAlertCriterion(
        icon: AppIcons.wallet,
        title: l10n.wantedAlertCriteriaPrice,
        value: priceLabel(
          l10n,
          filter.minPrice,
          filter.maxPrice,
          locale: locale,
        ),
        fallback: l10n.wantedAlertAnyPrice,
      ),
      WantedAlertCriterion(
        icon: AppIcons.verified,
        title: l10n.wantedAlertCriteriaCondition,
        value: filter.conditions.isEmpty
            ? null
            : [for (final condition in filter.conditions) condition.label(l10n)]
                  .join(', '),
        fallback: l10n.wantedAlertAnyCondition,
      ),
      WantedAlertCriterion(
        icon: AppIcons.swap,
        title: l10n.wantedAlertCriteriaDeal,
        value: filter.dealTypes.isEmpty
            ? null
            : [
                for (final type in filter.dealTypes) type.label(l10n),
              ].join(', '),
        fallback: l10n.wantedAlertAnyDeal,
      ),
      WantedAlertCriterion(
        icon: AppIcons.location,
        title: l10n.wantedAlertCriteriaArea,
        value: areaLabel,
        fallback: l10n.wantedAlertNationwide,
      ),
    ];
  }

  /// Nhãn ngắn của mức độ giống, VD "Mức độ giống: Vừa"
  static WantedAlertCriterion level(
    BuildContext context,
    WantedAlertMatchLevel level,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return WantedAlertCriterion(
      icon: AppIcons.sparkle,
      title: l10n.wantedAlertLevelTitle,
      value: level.label(l10n),
      fallback: level.label(l10n),
    );
  }

  /// "Từ 2 triệu", "Đến 5 triệu", "2 triệu – 5 triệu"; null khi không đặt
  static String? priceLabel(
    AppLocalizations l10n,
    int? min,
    int? max, {
    String? locale,
  }) {
    String format(int value) =>
        CurrencyFormatter.formatCompact(value, l10n, locale: locale);
    if (min != null && max != null) {
      return l10n.wantedAlertPriceRange(format(min), format(max));
    }
    if (min != null) return l10n.wantedAlertPriceFrom(format(min));
    if (max != null) return l10n.wantedAlertPriceUpTo(format(max));
    return null;
  }
}
