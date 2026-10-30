import 'dart:async';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

class LiveMessagesView extends StatefulWidget {
  const LiveMessagesView({super.key});
  @override
  State<LiveMessagesView> createState() => _LiveMessagesViewState();
}

class _LiveMessagesViewState extends State<LiveMessagesView> {
  final repository = ApiChatRepository();
  List<ChatConversation> conversations = [];
  Timer? refreshTimer;
  final _eventsCancel = CancelToken();
  StreamSubscription<String>? _events;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    unawaited(load());
    _events = repository.events(_eventsCancel).listen(
      (_) => unawaited(load()),
      onError: (Object _) {},
    );
    refreshTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(load()),
    );
  }

  Future<void> load() async {
    try {
      final items = await repository.listConversations();
      if (mounted) {
        setState(() {
          conversations = items;
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Không tải được tin nhắn.';
        });
      }
    }
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    _eventsCancel.cancel();
    unawaited(_events?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          Expanded(
            child: Center(
              child: TextButton(onPressed: load, child: Text('$error Thử lại')),
            ),
          )
        else if (conversations.isEmpty)
          const Expanded(
            child: Center(child: Text('Chưa có cuộc trò chuyện nào')),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: load,
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: conversations.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
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
                              ? NetworkImage(person.avatarUrl!)
                              : null,
                          child: person.avatarUrl == null
                              ? Text(initial)
                              : null,
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(AppIcons.chevronRight, size: 18),
                  );
                },
              ),
            ),
          ),
      ],
    ),
  );
}
