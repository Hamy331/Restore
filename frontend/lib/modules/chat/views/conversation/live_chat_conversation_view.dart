import 'live_chat_conversation_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/conversation/conversation_cubit.dart';
import '../../repositories/chat_repository.dart';

class LiveChatConversationView extends StatelessWidget {
  const LiveChatConversationView({
    required this.conversationId,
    this.repository,
    this.onBack,
    super.key,
  });
  final String conversationId;
  final ChatRepository? repository;

  /// Nút quay lại khi nhúng trong cửa sổ chat nổi (desktop); null thì đóng trang
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ConversationCubit(repository ?? ApiChatRepository(), conversationId)
          ..start(),
    child: LiveChatConversationMobileView(onBack: onBack),
  );
}
