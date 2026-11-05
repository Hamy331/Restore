import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'live_chat_conversation_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/conversation/conversation_cubit.dart';
import '../../repositories/chat_repository.dart';

class LiveChatConversationView extends StatelessWidget {
  const LiveChatConversationView({
    required this.conversationId,
    this.repository,
    super.key,
  });
  final String conversationId;
  final ChatRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ConversationCubit(repository ?? ApiChatRepository(), conversationId)
          ..start(),
    child: const TResponsiveLayout(mobile: LiveChatConversationMobileView()),
  );
}
