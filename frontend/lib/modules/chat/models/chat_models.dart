import '../../../core/network/media_url.dart';
import 'package:equatable/equatable.dart';

class ChatPerson extends Equatable {
  const ChatPerson({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.lastActiveAt,
    this.online,
  });
  final String id;
  final String fullName;
  final String? avatarUrl;
  final DateTime? lastActiveAt;

  final bool? online;
  bool get isOnline =>
      online ??
      (lastActiveAt != null &&
          DateTime.now().difference(lastActiveAt!).inSeconds < 120);

  factory ChatPerson.fromJson(Map<String, dynamic> json) => ChatPerson(
    id: json['id'] as String,
    online: json['isOnline'] as bool?,
    fullName: json['fullName'] as String? ?? '',
    avatarUrl: resolveMediaUrl(json['avatarUrl'] as String?),
    lastActiveAt: DateTime.tryParse(
      json['lastActiveAt'] as String? ?? '',
    )?.toLocal(),
  );

  @override
  List<Object?> get props => [id, fullName, avatarUrl, lastActiveAt, online];
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
    this.clientId,
    this.delivery,
    this.retryable = false,
  });
  final String? mediaName;
  final int? sequence;
  final String? clientId, delivery;
  final bool retryable;
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
    clientId: json['clientId'] as String?,
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
    clientId,
    delivery,
    retryable,
  ];
}

/// Đề nghị giá mới nhất của hội thoại theo tin.
/// status: PENDING, ACCEPTED, REJECTED, CANCELLED, EXPIRED
class ChatOffer extends Equatable {
  const ChatOffer(this.id, this.amount, this.status, {this.expiresAt});
  final String id, status;
  final num amount;
  final DateTime? expiresAt;

  bool get pending => status == 'PENDING';

  static ChatOffer? fromJson(Object? value) {
    if (value is! Map || value['id'] is! String) return null;
    return ChatOffer(
      value['id'] as String,
      num.tryParse('${value['amount']}') ?? 0,
      value['status'] as String? ?? 'PENDING',
      expiresAt: DateTime.tryParse('${value['expiresAt']}')?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, amount, status, expiresAt];
}

/// Thỏa thuận sau khi người bán chấp nhận đề nghị: trạng thái đánh giá
/// (double-blind) của người đang xem
class ChatAgreement extends Equatable {
  const ChatAgreement(
    this.price, {
    this.deadline,
    this.closed = false,
    this.published = false,
    this.otherReviewed = false,
    this.mine,
  });
  final num price;

  /// Đánh giá mình đã gửi (để sửa trước khi công khai)
  final ReviewDraft? mine;

  /// Hạn gửi / sửa đánh giá (30 ngày, hoặc 7 ngày sau đánh giá đầu tiên)
  final DateTime? deadline;

  /// Đã công khai hoặc đã hết hạn
  final bool closed;

  /// Đánh giá của mình đã công khai (không sửa được nữa)
  final bool published;

  /// Bên kia đã gửi đánh giá (chưa thấy nội dung)
  final bool otherReviewed;

  static ChatAgreement? fromJson(Object? value) {
    if (value is! Map) return null;
    return ChatAgreement(
      num.tryParse('${value['price']}') ?? 0,
      deadline: DateTime.tryParse('${value['deadline']}')?.toLocal(),
      closed: value['closed'] == true,
      published: value['published'] == true,
      otherReviewed: value['otherReviewed'] == true,
      mine: ReviewDraft.fromJson(value['mine']),
    );
  }

  @override
  List<Object?> get props => [
    price,
    deadline,
    closed,
    published,
    otherReviewed,
    mine,
  ];
}

/// Nội dung một đánh giá: số sao, tiêu chí, nhận xét
class ReviewDraft extends Equatable {
  const ReviewDraft(this.stars, this.comment, this.tags);
  final int stars;
  final String comment;
  final List<String> tags;

  static ReviewDraft? fromJson(Object? value) {
    if (value is! Map || value['stars'] is! num) return null;
    return ReviewDraft(
      (value['stars'] as num).toInt(),
      value['comment'] as String? ?? '',
      (value['tags'] as List? ?? const []).cast<String>(),
    );
  }

  @override
  List<Object?> get props => [stars, comment, tags];
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
    this.offer,
    this.agreement,
  });
  factory ChatTrade.fromJson(Map json) => ChatTrade(
    json['title'] as String,
    json['stage'] as String,
    json['seller'] == true,
    json['reviewed'] == true,
    product: ChatProduct.fromJson(json['product']),
    canOffer: json['canOffer'] == true,
    contextId: json['contextId'] as String?,
    offer: ChatOffer.fromJson(json['offer']),
    agreement: ChatAgreement.fromJson(json['agreement']),
  );

  /// open: trả giá được · offer: có đề nghị chờ · agreed: đã thống nhất ·
  /// closed: tin không còn bán
  final String title, stage;
  final String? contextId;
  final bool seller, reviewed;
  final ChatProduct? product;
  final bool canOffer;
  final ChatOffer? offer;
  final ChatAgreement? agreement;
  @override
  List<Object?> get props => [
    title,
    stage,
    seller,
    reviewed,
    contextId,
    product,
    canOffer,
    offer,
    agreement,
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

  ChatConversation updated({ChatPerson? person, ChatTrade? selectedTrade}) =>
      ChatConversation(
        id: id,
        otherUser: person ?? otherUser,
        unreadCount: unreadCount,
        lastMessage: lastMessage,
        trade: selectedTrade ?? trade,
        blocked: blocked,
        blockedByMe: blockedByMe,
        otherReadSequence: otherReadSequence,
        negotiating: negotiating,
      );

  ChatConversation presence(Map<String, dynamic> data) {
    if (otherUser.id != data['userId']) return this;
    return updated(
      person: ChatPerson(
        id: otherUser.id,
        fullName: otherUser.fullName,
        avatarUrl: otherUser.avatarUrl,
        online: data['isOnline'] == true,
        lastActiveAt: DateTime.tryParse(
          data['lastActiveAt']?.toString() ?? '',
        )?.toLocal(),
      ),
    );
  }

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
