import 'package:equatable/equatable.dart';

import 'enums/notification_type.dart';

/// Một thông báo trong app (bảng Notification).
///
/// App dựng câu chữ theo [type] + [data] (đa ngôn ngữ, xem
/// NotificationPresenter); [title] / [body] là câu tiếng Việt server ghi sẵn,
/// dùng khi app chưa biết loại này. [link] là route mở khi bấm vào.
class NotificationModel extends Equatable {
  final String id;
  final NotificationType type;

  /// Nhóm server trả về (giữ đúng cả khi [type] là unknown)
  final NotificationGroup group;
  final String title;
  final String body;

  /// Tham số: listingId, listingTitle, reason, amount, alertKeywords...
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? link;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.group,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data = const {},
    this.imageUrl,
    this.link,
    this.readAt,
  });

  bool get isRead => readAt != null;

  /// Chuỗi trong [data], null nếu thiếu hoặc rỗng
  String? text(String key) {
    final value = data[key];
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  /// Số nguyên trong [data], null nếu thiếu
  int? number(String key) {
    final value = data[key];
    return value is num ? value.toInt() : int.tryParse('${value ?? ''}');
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final type = NotificationType.fromApi(json['type'] as String?);
    final data = json['data'];
    final readAt = DateTime.tryParse('${json['readAt']}')?.toLocal();
    return NotificationModel(
      id: '${json['id']}',
      type: type,
      group: json['group'] is String
          ? NotificationGroup.fromApi(json['group'] as String)
          : type.group,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
      imageUrl: json['imageUrl'] as String?,
      link: json['link'] as String?,
      // Bản cũ chỉ có isRead: coi như đọc lúc tạo
      readAt:
          readAt ??
          (json['isRead'] == true
              ? DateTime.tryParse('${json['createdAt']}')?.toLocal()
              : null),
      createdAt:
          DateTime.tryParse('${json['createdAt']}')?.toLocal() ??
          DateTime.now(),
    );
  }

  NotificationModel markRead(DateTime at) => NotificationModel(
    id: id,
    type: type,
    group: group,
    title: title,
    body: body,
    data: data,
    imageUrl: imageUrl,
    link: link,
    readAt: readAt ?? at,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, type, readAt, createdAt];
}
