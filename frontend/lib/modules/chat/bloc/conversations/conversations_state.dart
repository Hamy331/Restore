import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';

class ConversationsState extends Equatable {
  const ConversationsState({
    this.conversations = const [],
    this.loading = true,
    this.failed = false,
    this.searchQuery = '',
  });
  final List<ChatConversation> conversations;
  final bool loading;
  final bool failed;
  final String searchQuery;

  List<ChatConversation> get visibleConversations {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return conversations;
    return conversations.where((conversation) {
      return conversation.otherUser.fullName.toLowerCase().contains(query) ||
          (conversation.lastMessage?.text.toLowerCase().contains(query) ??
              false);
    }).toList();
  }

  ConversationsState copyWith({
    List<ChatConversation>? conversations,
    bool? loading,
    bool? failed,
    String? searchQuery,
  }) => ConversationsState(
    conversations: conversations ?? this.conversations,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [conversations, loading, failed, searchQuery];
}
