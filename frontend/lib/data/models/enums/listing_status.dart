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
}
