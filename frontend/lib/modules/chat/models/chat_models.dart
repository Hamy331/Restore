class ChatPerson {
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
    avatarUrl: json['avatarUrl'] as String?,
    lastActiveAt: DateTime.tryParse(
      json['lastActiveAt'] as String? ?? '',
    )?.toLocal(),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    senderId: json['senderId'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.otherUser,
    required this.unreadCount,
    this.lastMessage,
  });
  final String id;
  final ChatPerson otherUser;
  final int unreadCount;
  final ChatMessage? lastMessage;

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'] as String,
        otherUser: ChatPerson.fromJson(
          Map<String, dynamic>.from(json['otherUser'] as Map),
        ),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        lastMessage: json['lastMessage'] is Map
            ? ChatMessage.fromJson(
                Map<String, dynamic>.from(json['lastMessage'] as Map),
              )
            : null,
      );
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
