import '../../../core/network/media_url.dart';
import 'package:equatable/equatable.dart';

class ChatPerson extends Equatable {
  const ChatPerson({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.lastActiveAt,
  });
  final String id;
  final String fullName;
  final String? avatarUrl;
  final DateTime? lastActiveAt;

  bool get isOnline =>
      lastActiveAt != null &&
      DateTime.now().difference(lastActiveAt!).inSeconds < 120;

  factory ChatPerson.fromJson(Map<String, dynamic> json) => ChatPerson(
    id: json['id'] as String,
    fullName: json['fullName'] as String? ?? '',
    avatarUrl: resolveMediaUrl(json['avatarUrl'] as String?),
    lastActiveAt: DateTime.tryParse(
      json['lastActiveAt'] as String? ?? '',
    )?.toLocal(),
  );

  @override
  List<Object?> get props => [id, fullName, avatarUrl, lastActiveAt];
}

class ChatProduct extends Equatable {
  const ChatProduct(this.id, this.title, this.price, this.image);
  final String id, title;
  final num? price;
  final String? image;

  static ChatProduct? fromJson(Object? value) {
    if (value is! Map || value['id'] is! String || value['title'] is! String) {
      return null;
    }
    return ChatProduct(
      value['id'] as String,
      value['title'] as String,
      num.tryParse(value['price']?.toString() ?? ''),
      value['image'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, price, image];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.product,
    this.mediaName,
    this.sequence,
  });
  final String? mediaName;
  final int? sequence;
  bool get isVideo =>
      const ['mp4', 'mov', 'webm'].contains(mediaName?.split('.').last);
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final ChatProduct? product;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    senderId: json['senderId'] as String,
    text: json['text'] as String,
    product: ChatProduct.fromJson(json['listingPreview']),
    mediaName: json['mediaName'] as String?,
    sequence: json['sequence'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );

  @override
  List<Object?> get props => [
    id,
    senderId,
    text,
    createdAt,
    product,
    mediaName,
    sequence,
  ];
}

class ChatTrade extends Equatable {
  const ChatTrade(
    this.title,
    this.stage,
    this.seller,
    this.reviewed, {
    this.product,
    this.canOffer = false,
    this.contextId,
  });
  factory ChatTrade.fromJson(Map json) => ChatTrade(
    json['title'] as String,
    json['stage'] as String,
    json['seller'] == true,
    json['reviewed'] == true,
    product: ChatProduct.fromJson(json['product']),
    canOffer: json['canOffer'] == true,
    contextId: json['contextId'] as String?,
  );
  final String title, stage;
  final String? contextId;
  final bool seller, reviewed;
  final ChatProduct? product;
  final bool canOffer;
  @override
  List<Object?> get props => [
    title,
    stage,
    seller,
    reviewed,
    contextId,
    product,
    canOffer,
  ];
}

class ChatConversation extends Equatable {
  const ChatConversation({
    required this.id,
    required this.otherUser,
    required this.unreadCount,
    this.lastMessage,
    this.trade,
    this.blocked = false,
    this.blockedByMe = false,
    this.otherReadSequence = 0,
    this.negotiating = false,
  });
  final String id;
  final ChatPerson otherUser;
  final int unreadCount;

  /// Người kia đã đọc tới tin có sequence này: tin của mình có sequence nhỏ
  /// hơn hoặc bằng là "Đã xem"
  final int otherReadSequence;

  /// Đã trả giá trên tin này, tin còn bán và chưa chốt: nhãn "Đang thương lượng"
  final bool negotiating;
  final ChatMessage? lastMessage;
  final ChatTrade? trade;
  final bool blocked, blockedByMe;

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'] as String,
        blocked: json['blocked'] == true,
        blockedByMe: json['blockedByMe'] == true,
        trade: json['listingContext'] is Map
            ? ChatTrade.fromJson(json['listingContext'] as Map)
            : null,
        otherUser: ChatPerson.fromJson(
          Map<String, dynamic>.from(json['otherUser'] as Map),
        ),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        otherReadSequence: (json['otherReadSequence'] as num?)?.toInt() ?? 0,
        negotiating: json['negotiating'] == true,
        lastMessage: json['lastMessage'] is Map
            ? ChatMessage.fromJson(
                Map<String, dynamic>.from(json['lastMessage'] as Map),
              )
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    otherUser,
    unreadCount,
    lastMessage,
    trade,
    blocked,
    blockedByMe,
    otherReadSequence,
    negotiating,
  ];
}

String activityLabel(ChatPerson person) {
  if (person.isOnline) return 'Đang hoạt động';
  final last = person.lastActiveAt;
  if (last == null) return 'Chưa có trạng thái hoạt động';
  final elapsed = DateTime.now().difference(last);
  if (elapsed.inMinutes < 1) return 'Hoạt động vừa xong';
  if (elapsed.inHours < 1) return 'Hoạt động ${elapsed.inMinutes} phút trước';
  if (elapsed.inDays < 1) return 'Hoạt động ${elapsed.inHours} giờ trước';
  return 'Hoạt động ${elapsed.inDays} ngày trước';
}
