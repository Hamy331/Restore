import 'package:flutter/material.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../../bloc/conversation/conversation_cubit.dart';
import '../../bloc/conversation/conversation_state.dart';
import '../../models/chat_models.dart';

/// Chỉ giữ controller của ô soạn tin và danh sách; dữ liệu nằm ở cubit.
class LiveChatConversationMobileView extends StatefulWidget {
  const LiveChatConversationMobileView({super.key});

  @override
  State<LiveChatConversationMobileView> createState() =>
      _LiveChatConversationMobileViewState();
}

class _LiveChatConversationMobileViewState
    extends State<LiveChatConversationMobileView> {
  final composer = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    composer.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (await context.read<ConversationCubit>().send(composer.text)) {
      composer.clear();
    }
  }

  void scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ConversationCubit, ConversationState>(
          listenWhen: (previous, current) =>
              current.sendFailed ||
              previous.messages.length != current.messages.length,
          listener: (context, state) {
            if (state.sendFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không gửi được tin nhắn. Thử lại nhé.'),
                ),
              );
            } else {
              scrollToBottom();
            }
          },
          builder: (context, state) {
            final person = state.conversation?.otherUser;
            return Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: () => context.pop(),
                      icon: const Icon(AppIcons.back),
                    ),
                    if (person != null) _Header(person: person),
                  ],
                ),
                const Divider(height: 1),
                if (state.loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.failed)
                  Expanded(
                    child: Center(
                      child: TextButton(
                        onPressed: cubit.load,
                        child: const Text(
                          'Không tải được cuộc trò chuyện. Thử lại',
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(14),
                      itemCount: state.messages.length,
                      itemBuilder: (_, index) {
                        final message = state.messages[index];
                        return _MessageBubble(
                          message: message,
                          mine: state.isMine(message),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: composer,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => send(),
                          decoration: const InputDecoration(
                            hintText: 'Nhắn tin...',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Gửi tin nhắn',
                        onPressed: state.sending ? null : send,
                        icon: const Icon(AppIcons.send),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.person});
  final ChatPerson person;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundImage: person.avatarUrl != null
              ? appImageProvider(person.avatarUrl!)
              : null,
          child: person.avatarUrl == null
              ? Text(person.fullName.isEmpty ? '?' : person.fullName[0])
              : null,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.fullName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                activityLabel(person),
                style: TextStyle(
                  fontSize: 11,
                  color: person.isOnline
                      ? const Color(0xFF22A06B)
                      : const Color(0xFF70695F),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 285),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFFFF1D6) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text),
            const SizedBox(height: 3),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF70695F)),
            ),
          ],
        ),
      ),
    );
  }
}
