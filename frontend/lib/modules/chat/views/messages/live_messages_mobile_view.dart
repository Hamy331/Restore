import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/utils/app_image_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import '../../bloc/conversations/conversations_cubit.dart';
import '../../bloc/conversations/conversations_state.dart';
import '../../models/chat_models.dart';

class LiveMessagesMobileView extends StatelessWidget {
  const LiveMessagesMobileView({
    super.key,
    required this.onSelect,
    this.selectedId,
    this.bottomPadding = 120,
  });

  final ValueChanged<String> onSelect;
  final String? selectedId;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationsCubit>();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          AppTabHeader(title: AppLocalizations.of(context)!.messagesTitle),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: BlocBuilder<ConversationsCubit, ConversationsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: AppLoadingIndicator());
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
                return AppPullToRefresh(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    itemCount: state.conversations.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: state.conversations[index],
                      selected: state.conversations[index].id == selectedId,
                      onTap: () => onSelect(state.conversations[index].id),
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
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });
  final ChatConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = conversation.otherUser;
    final initial = person.fullName.isNotEmpty
        ? person.fullName[0].toUpperCase()
        : '?';
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.primarySoft,
        selectedColor: AppColors.textPrimary,
        onTap: onTap,
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
      ),
    );
  }
}
