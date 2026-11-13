import 'package:restore/l10n/app_localizations.dart';

/// Backend hiện có AVAILABLE, RESERVED, SOLD, EXCHANGED. DRAFT, PENDING và EXPIRED (ListingStatus).
enum ListingStatus {
  draft('DRAFT'),
  pending('PENDING'),
  rejected('REJECTED'),
  hidden('HIDDEN'),
  available('AVAILABLE'),
  reserved('RESERVED'),
  sold('SOLD'),
  exchanged('EXCHANGED'),
  expired('EXPIRED');

  const ListingStatus(this.apiValue);

  final String apiValue;

  static ListingStatus? fromApi(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }

  /// Tin đã được duyệt (đang hiển thị hoặc đã ẩn): sửa thì tạo bản sửa chờ
  /// duyệt, người mua vẫn thấy bản cũ tới khi duyệt xong
  bool get isApproved => this == available || this == hidden;

  String label(AppLocalizations l10n) => switch (this) {
    draft => l10n.listingStatusDraft,
    pending => l10n.listingStatusPending,
    rejected => l10n.listingStatusRejected,
    hidden => l10n.listingStatusHidden,
    available => l10n.listingStatusAvailable,
    reserved => l10n.listingStatusReserved,
    sold => l10n.listingStatusSold,
    exchanged => l10n.listingStatusExchanged,
    expired => l10n.listingStatusExpired,
  };
}
