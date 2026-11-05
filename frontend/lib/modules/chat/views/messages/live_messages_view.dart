import 'package:restore/core/ui/layouts/t_responsive_layout.dart';
import 'live_messages_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/conversations/conversations_cubit.dart';
import '../../repositories/chat_repository.dart';

class LiveMessagesView extends StatelessWidget {
  const LiveMessagesView({super.key, this.repository});
  final ChatRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ConversationsCubit(repository ?? ApiChatRepository())..start(),
    child: const TResponsiveLayout(mobile: LiveMessagesMobileView()),
  );
}
