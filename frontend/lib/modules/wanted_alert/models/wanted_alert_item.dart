import 'package:equatable/equatable.dart';
import 'package:restore/data/models/wanted_alert_model.dart';
import 'package:restore/shared/models/localized_text.dart';

/// Một dòng ở trang quản lý: thông báo kèm số liệu backend tính sẵn
/// (`GET /wanted-alerts`).
class WantedAlertItem extends Equatable {
  final WantedAlertModel alert;

  /// Tên danh mục để hiện ngay, null khi không lọc danh mục
  final LocalizedText? categoryName;

  /// Tổng số tin đã khớp và số tin khớp người dùng chưa xem
  final int matchCount;
  final int newMatchCount;

  /// Ảnh bìa vài tin khớp gần nhất
  final List<String> previewImages;

  const WantedAlertItem({
    required this.alert,
    this.categoryName,
    this.matchCount = 0,
    this.newMatchCount = 0,
    this.previewImages = const [],
  });

  String get id => alert.id;

  factory WantedAlertItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return WantedAlertItem(
      alert: WantedAlertModel.fromJson(json),
      categoryName: category is Map
          ? LocalizedText.fromJson(category['name'])
          : null,
      matchCount: (json['matchCount'] as num?)?.toInt() ?? 0,
      newMatchCount: (json['newMatchCount'] as num?)?.toInt() ?? 0,
      previewImages: [
        for (final image in json['previewImages'] as List? ?? const [])
          '$image',
      ],
    );
  }

  /// Đã mở xem các tin khớp
  WantedAlertItem markSeen() => WantedAlertItem(
    alert: alert,
    categoryName: categoryName,
    matchCount: matchCount,
    previewImages: previewImages,
  );

  @override
  List<Object?> get props => [
    alert,
    categoryName,
    matchCount,
    newMatchCount,
    previewImages,
  ];
}
