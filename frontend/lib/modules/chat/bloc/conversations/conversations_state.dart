import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';

class ConversationsState extends Equatable {
  const ConversationsState({
    this.conversations = const [],
    this.loading = true,
    this.failed = false,
  });
  final List<ChatConversation> conversations;
  final bool loading;
  final bool failed;

  @override
  List<Object?> get props => [conversations, loading, failed];
}
