import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';

class ConversationState extends Equatable {
  const ConversationState({
    this.conversation,
    this.messages = const [],
    this.selfId,
    this.loading = true,
    this.failed = false,
    this.sending = false,
    this.sendFailed = false,
  });
  final ChatConversation? conversation;
  final List<ChatMessage> messages;

  /// Id của người dùng hiện tại, để căn tin của mình sang phải.
  final String? selfId;
  final bool loading, failed, sending;

  /// Lần gửi gần nhất bị lỗi; không giữ qua các lần emit sau.
  final bool sendFailed;

  bool isMine(ChatMessage message) => message.senderId == selfId;

  ConversationState copyWith({
    ChatConversation? conversation,
    List<ChatMessage>? messages,
    String? selfId,
    bool? loading,
    bool? failed,
    bool? sending,
    bool sendFailed = false,
  }) => ConversationState(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    selfId: selfId ?? this.selfId,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    sending: sending ?? this.sending,
    sendFailed: sendFailed,
  );

  @override
  List<Object?> get props => [
    conversation,
    messages,
    selfId,
    loading,
    failed,
    sending,
    sendFailed,
  ];
}
