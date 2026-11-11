import 'package:flutter/material.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../bloc/conversations/conversations_cubit.dart';
import '../../bloc/conversations/conversations_state.dart';
import '../../models/chat_models.dart';

class LiveMessagesMobileView extends StatelessWidget {
  const LiveMessagesMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationsCubit>();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tin nhắn',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ConversationsCubit, ConversationsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.failed && state.conversations.isEmpty) {
                  return Center(
                    child: TextButton(
                      onPressed: cubit.load,
                      child: const Text('Không tải được tin nhắn. Thử lại'),
                    ),
                  );
                }
                if (state.conversations.isEmpty) {
                  return const Center(
                    child: Text('Chưa có cuộc trò chuyện nào'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: state.conversations.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: state.conversations[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});
  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final person = conversation.otherUser;
    final initial = person.fullName.isNotEmpty
        ? person.fullName[0].toUpperCase()
        : '?';
    return ListTile(
      onTap: () => context.push('/messages/${conversation.id}'),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: person.avatarUrl != null
                ? appImageProvider(person.avatarUrl!)
                : null,
            child: person.avatarUrl == null ? Text(initial) : null,
          ),
          if (person.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF22A06B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        person.fullName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        conversation.lastMessage?.text ?? activityLabel(person),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conversation.unreadCount > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFE9A529),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            )
          : const Icon(AppIcons.chevronRight, size: 18),
    );
  }
}
