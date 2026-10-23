import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/listing_card_item.dart';

/// Một tin gần giống thông báo: tin gợi ý lúc soạn
/// (`POST /wanted-alerts/preview`) hoặc tin đã khớp
/// (`GET /wanted-alerts/:id/matches`). API trả về bản ghi tin như
/// [ListingCardItem] kèm `score`, `matchedAt`, `isNew`.
class WantedAlertMatch extends Equatable {
  final ListingCardItem item;

  /// Điểm giống 0..1 (xem `backend/docs/wanted-alerts.md`)
  final double score;

  /// Lúc backend ghi nhận khớp và gửi thông báo, null với tin gợi ý
  final DateTime? matchedAt;

  /// Người dùng chưa mở xem tin này
  final bool isNew;

  const WantedAlertMatch({
    required this.item,
    required this.score,
    this.matchedAt,
    this.isNew = false,
  });

  String get listingId => item.listing.id;

  /// Điểm giống dạng phần trăm để hiện trên thẻ, VD 82
  int get percent => (score * 100).round().clamp(0, 100);

  factory WantedAlertMatch.fromJson(Map<String, dynamic> json) =>
      WantedAlertMatch(
        item: ListingCardItem.fromJson(json),
        score: (json['score'] as num?)?.toDouble() ?? 0,
        matchedAt: DateTime.tryParse('${json['matchedAt']}'),
        isNew: json['isNew'] as bool? ?? false,
      );

  WantedAlertMatch copyWith({ListingCardItem? item, bool? isNew}) =>
      WantedAlertMatch(
        item: item ?? this.item,
        score: score,
        matchedAt: matchedAt,
        isNew: isNew ?? this.isNew,
      );

  @override
  List<Object?> get props => [item, score, matchedAt, isNew];
}
