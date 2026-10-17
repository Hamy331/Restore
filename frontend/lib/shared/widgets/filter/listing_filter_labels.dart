import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';

/// Nhãn hiển thị của các tiêu chí lọc, dùng chung cho mọi trang danh sách
extension ListingDealTypeLabel on ListingDealType {
  String label(AppLocalizations l10n) => switch (this) {
    ListingDealType.buy => l10n.listingDealBuy,
    ListingDealType.exchange => l10n.listingDealExchange,
  };
}

extension ListingSortLabel on ListingSort {
  String label(AppLocalizations l10n) => switch (this) {
    ListingSort.relevance => l10n.listingSortRelevance,
    ListingSort.nearest => l10n.listingSortNearest,
    ListingSort.newest => l10n.listingSortNewest,
    ListingSort.priceLow => l10n.listingSortPriceLow,
    ListingSort.priceHigh => l10n.listingSortPriceHigh,
  };
}
