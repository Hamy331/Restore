import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/shell/widgets/desktop_chat_controller.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import '../../bloc/conversations/conversations_cubit.dart';
import '../../repositories/chat_repository.dart';
import '../conversation/live_chat_conversation_view.dart';
import 'live_messages_mobile_view.dart';

class LiveMessagesView extends StatelessWidget {
  const LiveMessagesView({super.key, this.repository, this.conversationId});
  final ChatRepository? repository;
  final String? conversationId;

  static const path = '/messages';
  static const conversationParameter = 'conversation';

  static String? selectedConversation(Uri uri) {
    final id = uri.queryParameters[conversationParameter]?.trim();
    return uri.path == path && id != null && id.isNotEmpty ? id : null;
  }

  static String location({String? conversationId}) => Uri(
    path: path,
    queryParameters: conversationId == null
        ? null
        : {conversationParameter: conversationId},
  ).toString();

  void _select(BuildContext context, String id, {required bool split}) {
    if (id == conversationId) return;
    if (split) {
      context.go(location(conversationId: id));
    } else {
      context.push('$path/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = DesktopChatScope.maybeOf(context);
    final useSharedInbox = repository == null && shell != null;
    final userId = useSharedInbox ? context.watchUser()?.id : null;
    if (useSharedInbox && userId == null) return const SizedBox.shrink();
    final layout = LayoutBuilder(
      builder: (context, constraints) {
        final id = conversationId;
        final split = isDesktopLayout(context) && constraints.maxWidth >= 720;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (split || id == null)
              SizedBox(
                width: split
                    ? math.min(360.0, constraints.maxWidth * 0.38)
                    : constraints.maxWidth,
                child: LiveMessagesMobileView(
                  selectedId: id,
                  bottomPadding: split ? 16 : 120,
                  onSelect: (id) => _select(context, id, split: split),
                ),
              ),
            if (split) const VerticalDivider(width: 1, color: AppColors.border),
            if (id != null)
              Expanded(
                key: ValueKey(id),
                child: LiveChatConversationView(
                  conversationId: id,
                  repository: repository,
                  onBack: split ? () => context.go(path) : null,
                ),
              )
            else if (split)
              const Expanded(child: _PickConversation()),
          ],
        );
      },
    );
    if (shell != null && userId != null) {
      return BlocProvider.value(value: shell.inboxFor(userId), child: layout);
    }
    return BlocProvider(
      create: (_) =>
          ConversationsCubit(repository ?? ApiChatRepository())..start(),
      child: layout,
    );
  }
}

class _PickConversation extends StatelessWidget {
  const _PickConversation();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.background,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.chat, size: 44, color: AppColors.primaryDark),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.messagesPickConversation),
        ],
      ),
    ),
  );
}
