import 'package:equatable/equatable.dart';

/// Trạng thái hiển thị của poster (backend tính từ status + khung giờ)
enum ShopPosterState {
  pending('PENDING'),
  scheduled('SCHEDULED'),
  running('RUNNING'),
  ended('ENDED'),
  rejected('REJECTED'),
  stopped('STOPPED');

  const ShopPosterState(this.apiValue);

  final String apiValue;

  static ShopPosterState fromApi(String? value) => values.firstWhere(
    (state) => state.apiValue == value,
    orElse: () => ShopPosterState.pending,
  );

  /// Còn sửa được (sửa xong quay về chờ duyệt)
  bool get editable =>
      this == pending ||
      this == scheduled ||
      this == running ||
      this == rejected;

  /// Còn dừng / hủy được
  bool get stoppable => this == pending || this == scheduled || this == running;
}

/// Lý do admin từ chối poster
enum PosterRejectReason {
  wrongSize('WRONG_SIZE'),
  misleadingPrice('MISLEADING_PRICE'),
  brandMisuse('BRAND_MISUSE'),
  prohibited('PROHIBITED'),
  tooMuchText('TOO_MUCH_TEXT'),
  other('OTHER');

  const PosterRejectReason(this.apiValue);

  final String apiValue;

  static PosterRejectReason? fromApi(String? value) {
    for (final reason in values) {
      if (reason.apiValue == value) return reason;
    }
    return null;
  }
}

/// Tin của shop mà poster mở khi bấm vào
class PosterListingRef extends Equatable {
  const PosterListingRef({
    required this.id,
    required this.title,
    this.image,
    this.available = true,
  });

  final String id;
  final String title;
  final String? image;

  /// Tin còn đang bán không (tin đã bán / ẩn thì poster mở trang shop)
  final bool available;

  factory PosterListingRef.fromJson(Map<String, dynamic> json) =>
      PosterListingRef(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        image: json['image'] as String?,
        available: json['available'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, title, image, available];
}

/// Một poster của shop trong trang quản lý (`GET /shops/me/posters`)
class ShopPoster extends Equatable {
  const ShopPoster({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.state,
    this.startsAt,
    this.endsAt,
    this.days,
    this.listing,
    this.rejectReason,
    this.rejectNote,
    this.createdAt,
  });

  final String id;
  final String title;

  /// Ảnh 2:1 shop tự thiết kế (đường dẫn `/api/v1/media/posters/...` hoặc asset)
  final String imageUrl;
  final ShopPosterState state;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? days;
  final PosterListingRef? listing;
  final PosterRejectReason? rejectReason;
  final String? rejectNote;
  final DateTime? createdAt;

  factory ShopPoster.fromJson(Map<String, dynamic> json) => ShopPoster(
    id: '${json['id']}',
    title: json['title'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    state: ShopPosterState.fromApi(json['state'] as String?),
    startsAt: DateTime.tryParse('${json['startsAt']}')?.toLocal(),
    endsAt: DateTime.tryParse('${json['endsAt']}')?.toLocal(),
    days: (json['days'] as num?)?.toInt(),
    listing: json['listing'] is Map
        ? PosterListingRef.fromJson(
            Map<String, dynamic>.from(json['listing'] as Map),
          )
        : null,
    rejectReason: PosterRejectReason.fromApi(json['rejectReason'] as String?),
    rejectNote: json['rejectNote'] as String?,
    createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
  );

  ShopPoster copyWith({ShopPosterState? state, DateTime? endsAt}) => ShopPoster(
    id: id,
    title: title,
    imageUrl: imageUrl,
    state: state ?? this.state,
    startsAt: startsAt,
    endsAt: endsAt ?? this.endsAt,
    days: days,
    listing: listing,
    rejectReason: rejectReason,
    rejectNote: rejectNote,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    imageUrl,
    state,
    startsAt,
    endsAt,
    days,
    listing,
    rejectReason,
    rejectNote,
    createdAt,
  ];
}
