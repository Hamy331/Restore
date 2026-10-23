import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/shop_banner_status.dart';

/// Một dòng của bảng ShopBanner (đề xuất, xem `backend/docs/trusted-shops.md`):
/// banner sự kiện / ưu đãi do shop gửi lên, admin duyệt rồi mới hiện trên
/// trang chủ, trang Shop uy tín và trang của shop. Banner chỉ là một ảnh shop
/// tự thiết kế (chữ nằm sẵn trong ảnh); bấm vào mở thẳng trang shop.
class ShopBannerModel extends Equatable {
  final String id;
  final String shopId;

  /// Tên chiến dịch, VD "Tuần lễ Kodo Z30": không vẽ lên ảnh, dùng cho trình
  /// đọc màn hình và trang quản lý banner
  final String title;

  /// Ảnh banner 1200 × 600 (tỉ lệ 2:1, giống banner trang chủ)
  final String imageUrl;

  /// Thời gian chạy; null là không giới hạn
  final DateTime? startsAt;
  final DateTime? endsAt;
  final ShopBannerStatus status;
  final DateTime? createdAt;

  const ShopBannerModel({
    required this.id,
    required this.shopId,
    required this.imageUrl,
    this.title = '',
    this.startsAt,
    this.endsAt,
    this.status = ShopBannerStatus.approved,
    this.createdAt,
  });

  factory ShopBannerModel.fromJson(Map<String, dynamic> json) =>
      ShopBannerModel(
        id: '${json['id']}',
        shopId: '${json['shopId'] ?? ''}',
        title: json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        startsAt: DateTime.tryParse('${json['startsAt']}'),
        endsAt: DateTime.tryParse('${json['endsAt']}'),
        status:
            ShopBannerStatus.fromApi(json['status'] as String?) ??
            ShopBannerStatus.approved,
        createdAt: DateTime.tryParse('${json['createdAt']}'),
      );

  @override
  List<Object?> get props => [
    id,
    shopId,
    title,
    imageUrl,
    startsAt,
    endsAt,
    status,
    createdAt,
  ];
}
