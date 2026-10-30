import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/modules/auth/repositories/auth_repository.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

class LiveChatConversationView extends StatefulWidget {
  const LiveChatConversationView({required this.conversationId, super.key});
  final String conversationId;

  @override
  State<LiveChatConversationView> createState() =>
      _LiveChatConversationViewState();
}

class _LiveChatConversationViewState extends State<LiveChatConversationView> {
  final repository = ApiChatRepository();
  final composer = TextEditingController();
  final scrollController = ScrollController();
  ChatConversation? conversation;
  List<ChatMessage> messages = [];
  String? selfId;
  String? error;
  bool loading = true;
  bool sending = false;
  Timer? refreshTimer;
  final _eventsCancel = CancelToken();
  StreamSubscription<String>? _events;

  @override
  void initState() {
    super.initState();
    unawaited(load());
    _events = repository.events(_eventsCancel).listen(
      (event) {
        if (event == 'message' || event == 'presence') {
          unawaited(load(silent: true));
        }
      },
      onError: (Object _) {},
    );
    refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(load(silent: true)),
    );
  }

  Future<void> load({bool silent = false}) async {
    try {
      final user = selfId == null ? await AuthRepository().currentUser() : null;
      final results = await Future.wait<dynamic>([
        repository.getConversation(widget.conversationId),
        repository.getMessages(widget.conversationId),
      ]);
      await repository.markRead(widget.conversationId);
      if (!mounted) return;
      setState(() {
        selfId = user?['id'] as String? ?? selfId;
        conversation = results[0] as ChatConversation;
        messages = results[1] as List<ChatMessage>;
        loading = false;
        error = null;
      });
      if (!silent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() {
          loading = false;
          error = 'Không tải được cuộc trò chuyện.';
        });
      }
    }
  }

  Future<void> send() async {
    final text = composer.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    final clientId =
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
    try {
      await repository.sendMessage(widget.conversationId, clientId, text);
      composer.clear();
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không gửi được tin nhắn. Thử lại nhé.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    _eventsCancel.cancel();
    unawaited(_events?.cancel());
    composer.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final person = conversation?.otherUser;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => context.pop(),
                  icon: const Icon(AppIcons.back),
                ),
                if (person != null) ...[
                  CircleAvatar(
                    radius: 19,
                    backgroundImage: person.avatarUrl != null
                        ? NetworkImage(person.avatarUrl!)
                        : null,
                    child: person.avatarUrl == null
                        ? Text(
                            person.fullName.isEmpty ? '?' : person.fullName[0],
                          )
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
              ],
            ),
            const Divider(height: 1),
            if (loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Expanded(
                child: Center(
                  child: TextButton(
                    onPressed: load,
                    child: Text('$error Thử lại'),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final message = messages[index];
                    final mine = message.senderId == selfId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 285),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFFFFF1D6)
                              : const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(message.text),
                            const SizedBox(height: 3),
                            Text(
                              '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF70695F),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    onPressed: sending ? null : send,
                    icon: const Icon(AppIcons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
